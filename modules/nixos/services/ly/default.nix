{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.fs.services.ly = {
    enable = lib.mkOption {
      description = "Whether to enable Ly display manager.";
      default = false;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf config.fs.services.ly.enable {
    services.displayManager = {
      ly = {
        enable = true;
        package = pkgs.ly;
      };
    };
  };
}
