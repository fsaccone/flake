{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.desktop.wayland = {
    enable = lib.mkEnableOption "Enables Ly and Sway";
  };

  config = lib.mkIf config.modules.desktop.wayland.enable {
    services.displayManager = {
      defaultSession = "Sway";
      ly = {
        enable = true;
        package = pkgs.ly;
      };
    };

    programs.sway = {
      enable = true;
      package = pkgs.sway;
      extraPackages = [ ];
    };

    services.logind = {
      killUserProcesses = true;
      lidSwitch = "poweroff";
      powerKey = "poweroff";
      powerKeyLongPress = "poweroff";
    };
  };
}
