{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.git.daemon = {
    enable = lib.mkOption {
      description = "Whether to enable the Git daemon.";
      default = false;
      type = lib.types.bool;
    };
  };

  config =
    let
      inherit (config.modules.git) daemon;
    in
    lib.mkIf (config.modules.git.enable && daemon.enable) {
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
                    --base-path=${config.modules.git.directory} \
                    --port=9418 \
                    --export-all \
                    ${config.modules.git.directory}
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
