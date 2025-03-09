{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.amfora = {
    enable = lib.mkOption {
      description = "Whether to enable Amfora.";
      default = false;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf config.modules.amfora.enable {
    home.packages = [ pkgs.amfora ];
  };
}
