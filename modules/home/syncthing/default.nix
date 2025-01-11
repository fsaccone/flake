{
  lib,
  options,
  config,
  ...
}:
{
  options.modules = {
    syncthing.enable = lib.mkEnableOption "Enables Syncthing";
  };

  config = lib.mkIf config.modules.syncthing.enable {
    services.syncthing = {
      enable = true;
    };
  };
}
