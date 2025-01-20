{
  lib,
  options,
  config,
  ...
}:
{
  options.modules.networkmanager = {
    enable = lib.mkEnableOption "Enables NetworkManager";
  };

  config = lib.mkIf config.modules.networkmanager.enable {
    networking.networkmanager = {
      enable = true;
    };
  };
}
