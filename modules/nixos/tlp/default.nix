{
  lib,
  options,
  config,
  ...
}:
{
  options.services.tlp = {
    enable = lib.mkOption {
      description = "Whether to enable TLP.";
      default = false;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf config.services.tlp.enable {
    services.tlp = {
      enable = true;
    };
  };
}
