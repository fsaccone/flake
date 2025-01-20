{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.mediaViewers = {
    enable = lib.mkEnableOption "Enables media viewers";
  };

  config = lib.mkIf config.modules.mediaViewers.enable {
    programs.imv = {
      enable = true;
      package = pkgs.imv;
    };

    programs.mpv = {
      enable = true;
      package = pkgs.mpv-unwrapped;
    };
  };
}
