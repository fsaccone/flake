{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.sway = {
    enable = lib.mkOption {
      description = "Whether to enable Sway.";
      default = false;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf config.modules.sway.enable {
    services.displayManager = {
      defaultSession = "Sway";
    };

    programs.sway = {
      enable = true;
      package = pkgs.sway;
      extraPackages = lib.mkForce [ ];
    };
  };
}
