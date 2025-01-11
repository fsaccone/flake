{
  lib,
  options,
  config,
  ...
}:
{
  options.modules = {
    syncthing.enable = lib.mkEnableOption "enables syncthing";
  };

  config = lib.mkIf config.modules.syncthing.enable {
    services.syncthing = {
      enable = true;
    };
  };
}
