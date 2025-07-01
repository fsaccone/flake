{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.fs.services.sway = {
    enable = lib.mkOption {
      description = "Whether to enable Sway.";
      default = false;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf config.fs.services.sway.enable {
    services.displayManager = {
      defaultSession = "Sway";
    };

    programs.sway = {
      enable = true;
      package = pkgs.sway;
      extraPackages = lib.mkForce [ ];
    };

    services.logind = {
      powerKey = "ignore";
      powerKeyLongPress = "poweroff";
      lidSwitch = "sleep";
    };

    security.pam.services.waylock = { };
  };
}
