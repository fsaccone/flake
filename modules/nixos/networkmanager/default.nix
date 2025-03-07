{
  lib,
  options,
  config,
  ...
}:
{
  options.modules.networkmanager = {
    enable = lib.mkOption {
      description = "Whether to enable NetworkManager.";
      default = false;
      type = lib.types.bool;
    };
    randomiseMacAddress = lib.mkOption {
      description = "Whether to randomise the MAC address of each interface.";
      default = false;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf config.modules.networkmanager.enable {
    networking.networkmanager =
      let
        inherit (config.modules.networkmanager) randomiseMacAddress;
        macAddress = if randomiseMacAddress then "random" else "preserve";
      in
      {
        enable = true;
        wifi = { inherit macAddress; };
        ethernet = { inherit macAddress; };
      };
  };
}
