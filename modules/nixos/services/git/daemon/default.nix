{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.fs.services.git.daemon = {
    enable = lib.mkOption {
      description = "Whether to enable the Git daemon.";
      default = false;
      type = lib.types.bool;
    };
  };

  config =
    let
      inherit (config.fs.services.git) daemon;
    in
    lib.mkIf (config.fs.services.git.enable && daemon.enable) {
      systemd = {
        services = {
          git-daemon = {
            enable = true;
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            serviceConfig =
              let
                script = pkgs.writeShellScriptBin "script" ''
                  ${pkgs.git}/bin/git daemon \
                    --verbose \
                    --syslog \
                    --base-path=${config.fs.services.git.directory} \
                    --port=9418 \
                    --export-all \
                    ${config.fs.services.git.directory}
                '';
              in
              {
                User = "git";
                Group = "git";
                Type = "simple";
                ExecStart = "${script}/bin/script";
              };
          };
        };
      };

      networking.firewall.allowedTCPPorts = [ 9418 ];
    };
}
