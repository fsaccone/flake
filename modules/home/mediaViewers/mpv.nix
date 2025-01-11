{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.mediaViewers = {
    mpv.enable = lib.mkEnableOption "enables mpv";
  };

  config = lib.mkIf config.modules.mediaViewers.mpv.enable {
    programs.mpv = {
      enable = true;
      package = pkgs.mpv-unwrapped;
    };
  };
}
