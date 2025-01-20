{
  lib,
  options,
  config,
  ...
}:
{
  options.modules.monero = {
    enable = lib.mkEnableOption "Enables Monero daemon";
    mining = {
      enable = lib.mkEnableOption "Enables Monero mining";
      address = lib.mkOption {
        type = lib.types.uniq lib.types.str;
        description = "The Monero address where to send rewards.";
      };
    };
  };

  config = lib.mkIf config.modules.monero.enable {
    services.monero = {
      enable = true;

      mining =
        if config.modules.monero.mining.enable then
          {
            enable = true;
            inherit (config.modules.monero.mining) address;
            threads = 0;
          }
        else
          { };
    };
  };
}
