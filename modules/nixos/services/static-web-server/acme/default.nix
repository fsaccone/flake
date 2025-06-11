{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.fs.services.static-web-server.acme = {
    enable = lib.mkOption {
      description = "Whether to enable the Certbot ACME client.";
      default = false;
      type = lib.types.bool;
    };
    directory = lib.mkOption {
      description = ''
        The directory containing fetched Let's Encrypt certificates.
      '';
      default = "/etc/letsencrypt/live";
      readOnly = true;
      type = lib.types.uniq lib.types.path;
    };
    email = lib.mkOption {
      description = "The email used for the Let's Encrypt account.";
      type = lib.types.uniq lib.types.str;
    };
    domain = lib.mkOption {
      description = "The domain to fetch the certificate for.";
      type = lib.types.uniq lib.types.str;
    };
    extraDomains = lib.mkOption {
      description = "The extra domains of the certificate.";
      default = [ ];
      type = lib.types.listOf lib.types.str;
    };
  };

  config =
    let
      inherit (config.fs.services.static-web-server) acme;
    in
    lib.mkIf (acme.enable && config.fs.services.static-web-server.enable) {
      systemd = {
        services = {
          acme = {
            enable = true;
            wantedBy = [ "multi-user.target" ];
            after = [ "static-web-server.target" ];
            serviceConfig =
              let
                domains = [ acme.domain ] ++ acme.extraDomains;

                script = pkgs.writeShellScriptBin "script" ''
                  if ${pkgs.certbot}/bin/certbot certificates \
                  | ${pkgs.gnugrep}/bin/grep -q "No certificates"; then
                    ${pkgs.certbot}/bin/certbot certonly --quiet --webroot \
                    --agree-tos --email ${acme.email} \
                    -w ${config.fs.services.static-web-server.directory} \
                    -d ${builtins.concatStringsSep "," domains}
                  else
                    ${pkgs.certbot}/bin/certbot renew --quiet
                  fi
                '';
              in
              {
                User = "root";
                Group = "root";
                Type = "oneshot";
                ExecStart = "${script}/bin/script";
              };
          };
        };
        timers = {
          acme = {
            enable = true;
            wantedBy = [ "multi-user.target" ];
            timerConfig = {
              OnCalendar = "daily";
              Persistent = true;
            };
          };
        };
      };
    };
}
