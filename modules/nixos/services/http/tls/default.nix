{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.fs.services.http.tls = {
    enable = lib.mkOption {
      description = "Whether to enable the Hitch reverse proxy.";
      default = false;
      type = lib.types.bool;
    };
    pemFiles = lib.mkOption {
      description = "The list of PEM files to pass to Hitch.";
      type = lib.types.listOf lib.types.path;
    };
  };

  config =
    let
      inherit (config.fs.services.http) tls;
    in
    lib.mkIf (tls.enable && config.fs.services.http.enable) {
      systemd.services.http-tls = {
        enable = true;
        wantedBy = [ "multi-user.target" ];
        after = [
          "http.service"
          "acme.service"
        ];
        serviceConfig = {
          User = "root";
          Group = "root";
          Type = "simple";
          Restart = "on-failure";
          ExecStart = pkgs.writeShellScript "http-tls.sh" ''
            mkdir -p /var/lib/hitch

            cat ${builtins.concatStringsSep " " tls.pemFiles} > \
              /var/lib/hitch/full.pem

            ${pkgs.hitch}/bin/hitch \
              --backend [localhost]:80 \
              --frontend [*]:443 \
              --backend-connect-timeout 30 \
              --ssl-handshake-timeout 30 \
              --ocsp-dir /var/lib/hitch \
              --user nobody \
              --group nogroup \
              /var/lib/hitch/full.pem
          '';
        };
      };

      networking.firewall.allowedTCPPorts = [ 443 ];
    };
}
