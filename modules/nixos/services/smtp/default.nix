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

                action in mbox
                action out relay

                match from any for domain ${domain} action in
                match for any action out

                listen on localhost smtps verify pki default
                listen on localhost tls pki default
              '';
            in
            {
              User = "root";
              Group = "root";
              Restart = "on-failure";
              Type = "simple";
              ExecStart = pkgs.writeShellScript "smtp" ''
                ${pkgs.opensmtpd}/bin/smtpd -df ${configuration}
              '';
            };
        };
      };
    };

    networking.firewall.allowedTCPPorts = [
      25
      465
    ];
  };
}
