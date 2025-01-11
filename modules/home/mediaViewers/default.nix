{
  lib,
  options,
  config,
  ...
}:
{
  imports = [
    ./imv.nix
    ./mpv.nix
  ];

  options.modules = {
    mediaViewers.enable = lib.mkEnableOption "enables media viewers";
  };

  config.modules.mediaViewers = lib.mkIf config.modules.mediaViewers.enable {
    imv.enable = lib.mkDefault true;
    mpv.enable = lib.mkDefault true;
  };
}
