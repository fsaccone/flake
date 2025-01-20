{
  lib,
  options,
  config,
  ...
}:
{
  options.modules.networking.searx = {
    enable = lib.mkEnableOption "Enables Searx";
    port = lib.mkOption {
      type = lib.types.uniq lib.types.int;
      description = "The local port that Searx is hosted in.";
    };
    secretKey = lib.mkOption {
      type = lib.types.uniq lib.types.str;
      description = "The secret key used by Searx.";
    };
  };

  config = lib.mkIf config.modules.networking.searx.enable {
    services.searx = {
      enable = true;

      redisCreateLocally = true;
      settings.server = {
        bind_address = "localhost";
        inherit (config.modules.networking.searx) port;
        secret_key = config.modules.networking.searx.secretKey;
      };
    };
  };
}
