{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.sway.components = {
    alacritty.enable = lib.mkEnableOption "Enables Alacritty";
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
            family = config.modules.sway.fonts.monospace;
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
