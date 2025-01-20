{
  lib,
  options,
  config,
  ...
}:
{
  options.modules.searx = {
    enable = lib.mkEnableOption "Enables Searx";
  };

  config = lib.mkIf config.modules.searx.enable {
    services.searx = {
      enable = true;

      redisCreateLocally = true;
      settings.server = {
        bind_address = "localhost";
        port = 8888;
        secret_key = builtins.getEnv "SEARX_SECRET_KEY";
      };
    };
  };
}
