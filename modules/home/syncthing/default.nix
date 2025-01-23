{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.syncthing = {
    enable = lib.mkEnableOption "Enables Syncthing";
    port = lib.mkOption {
      type = lib.types.uniq lib.types.int;
      description = "The local port where the Syncthing web UI will be hosted.";
    };
  };

  config = lib.mkIf config.modules.syncthing.enable {
    services.syncthing = {
      enable = true;
      extraOptions = [
        "--gui-address=localhost:${builtins.toString config.modules.syncthing.port}"
        "--config=${config.home.homeDirectory}/.config/syncthing"
        "--data=${config.home.homeDirectory}/.config/syncthing"
        "--no-default-folder"
      ];
    };
  };
}
