{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.fs.services.smtp = {
    enable = lib.mkOption {
      description = "Whether to enable the SMTP server using OpenSMTPD.";
      default = false;
      type = lib.types.bool;
    };
    domain = lib.mkOption {
      description = "The domain to host SMTP for.";
      type = lib.types.uniq lib.types.str;
    };
    users = lib.mkOption {
      description = "For each email user, its password hash.";
      default = { };
      type = lib.types.attrsOf lib.types.str;
    };
    tls = {
      certificate = lib.mkOption {
        description = "The path to the TLS certificate file.";
        type = lib.types.uniq lib.types.path;
      };
      key = lib.mkOption {
        description = "The path to the TLS key file.";
        type = lib.types.uniq lib.types.path;
      };
    };
  };

  config = lib.mkIf config.fs.services.smtp.enable {
    users = {
      users =
        (
          config.fs.services.smtp.users
          |> builtins.mapAttrs (
            user: hashedPassword: {
              inherit hashedPassword;
              isSystemUser = true;
              group = "email";
              createHome = true;
              home = "/home/${user}";
            }
          )
        )
        // {
          smtpd = {
            hashedPassword = "!";
            isSystemUser = true;
            group = "smtpd";
          };
          smtpq = {
            hashedPassword = "!";
            isSystemUser = true;
            group = "smtpq";
          };
        };
      groups = {
        email = { };
        smtpd = { };
        smtpq = { };
      };
    };

    systemd = {
      services = {
        smtp = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          serviceConfig =
            let
              inherit (config.fs.services.smtp) domain tls;

              configuration = builtins.toFile "smtpd.conf" ''
                pki default cert "${tls.certificate}"
                pki default key "${tls.key}"

                filter check-rdns phase connect \
                  match !rdns disconnect "no rDNS"
                filter check-fcrdns phase connect \
                  match !fcrdns disconnect "no FCrDNS"

                action in maildir junk
                action out relay

                match from any for domain ${domain} action in
                match for any action out

                listen on 0.0.0.0 smtps verify pki default auth \
                  filter { check-rdns, check-fcrdns }
                listen on :: smtps verify pki default auth \
                  filter { check-rdns, check-fcrdns }

                listen on 0.0.0.0 tls pki default auth \
                  filter { check-rdns, check-fcrdns }
                listen on :: tls pki default auth \
                  filter { check-rdns, check-fcrdns }

                listen on 0.0.0.0 port 587 tls-require pki default auth
                listen on :: port 587 tls-require pki default auth
              '';
            in
            {
              User = "root";
              Group = "root";
              Restart = "on-failure";
              Type = "simple";
              ExecStart = pkgs.writeShellScript "smtp" ''
                ${pkgs.opensmtpd}/bin/smtpd -dvf ${configuration}
              '';
            };
        };
      };
    };

    networking.firewall.allowedTCPPorts = [
      25
      465
      587
    ];
  };
}
