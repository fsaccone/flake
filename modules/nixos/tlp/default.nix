{
  lib,
  options,
  config,
  ...
}:
{
  options.modules.tlp = {
    enable = lib.mkEnableOption "Enables TLP";
  };

  config = lib.mkIf config.modules.tlp.enable {
    services.tlp = {
      enable = true;
    };
  };
}
