{
  lib,
  options,
  config,
  ...
}:
{
  options.modules.tlp = {
    enable = lib.mkOption {
      description = "Whether to enable TLP.";
      default = false;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf config.modules.tlp.enable {
    services.tlp = {
      enable = true;
    };
  };
}
