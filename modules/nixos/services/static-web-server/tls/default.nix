{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.fs.services.static-web-server.tls = {
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
      inherit (config.fs.services.static-web-server) tls;
    in
    lib.mkIf (tls.enable && config.fs.services.static-web-server.enable) {
      systemd.services.hitch = {
        enable = true;
        wantedBy = [ "multi-user.target" ];
        after = [ "acme.service" ];
        serviceConfig =
          let
            script = pkgs.writeShellScriptBin "script" ''
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
          in
          {
            User = "root";
            Group = "root";
            Type = "simple";
            Restart = "on-failure";
            ExecStart = "${script}/bin/script";
          };
      };

      networking.firewall.allowedTCPPorts = [ 443 ];
    };
}
