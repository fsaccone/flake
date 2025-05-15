{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.security.doas = {
    enable = lib.mkOption {
      description = "Whether to enable the doas command.";
      default = false;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf config.security.doas.enable {
    security.doas = {
      enable = true;
      wheelNeedsPassword = true;
    };
  };
}
