{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.sway.components = {
    alacritty.enable = lib.mkEnableOption "enables alacritty";
  };

  config = lib.mkIf config.modules.sway.components.alacritty.enable {
    programs.alacritty = {
      enable = true;
      package = pkgs.alacritty;

      settings = {
        window = {
          title = "Alacritty";
          dynamic_title = false;
        };
        font = {
          normal = {
            family = "IBM Plex Mono";
            style = "Regular";
          };
          size = 10;
        };
        colors.primary = {
          foreground = "#ffffff";
          background = "#000000";
        };
      };
    };
  };
}
