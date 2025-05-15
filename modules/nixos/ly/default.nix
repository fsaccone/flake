{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.services.ly = {
    enable = lib.mkOption {
      description = "Whether to enable Ly display manager.";
      default = false;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf config.services.ly.enable {
    services.displayManager = {
      ly = {
        enable = true;
        package = pkgs.ly;
      };
    };
  };
}
