{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules = {
    sway.enable = lib.mkEnableOption "Enables Ly and Sway";
  };

  config = lib.mkIf config.modules.sway.enable {
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
