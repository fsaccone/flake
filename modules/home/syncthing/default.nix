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
        "--gui-address=localhost:${config.modules.syncthing.port}"
        "--home=${config.home.homeDirectory}"
      ];
    };
  };
}
