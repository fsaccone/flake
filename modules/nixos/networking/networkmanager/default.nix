{
  lib,
  options,
  config,
  ...
}:
{
  options.modules.networking.networkmanager = {
    enable = lib.mkEnableOption "Enables NetworkManager";
  };

  config = lib.mkIf config.modules.networking.networkmanager.enable {
    networking.networkmanager = {
      enable = true;
    };
  };
}
