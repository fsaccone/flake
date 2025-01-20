{
  lib,
  options,
  config,
  ...
}:
{
  options.modules.system.tlp = {
    enable = lib.mkEnableOption "Enables TLP";
  };

  config = lib.mkIf config.modules.system.tlp.enable {
    services.tlp = {
      enable = true;
    };
  };
}
