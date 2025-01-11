{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules = {
    fonts.enable = lib.mkEnableOption "Install fonts";
  };

  config = lib.mkIf config.modules.fonts.enable {
    fonts.packages = with pkgs; [
      ibm-plex
    ];
  };
}
