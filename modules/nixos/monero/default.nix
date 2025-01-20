{
  lib,
  options,
  config,
  ...
}:
{
  options.modules.monero = {
    enable = lib.mkEnableOption "Enables Monero daemon";
  };

  config = lib.mkIf config.modules.monero.enable {
    services.monero = {
      enable = true;

      mining = {
        enable = true;
        address = ''
          44UAWDBRoxtXodXboy6LKEjokehoSiHwmNhgSYEvqzbiTmUnvMcNccFNsaAp7GCbDKhu62oeiEuj9HsPtwJi1p9V26ShoDh
        '';
        threads = 0;
      };
    };
  };
}
