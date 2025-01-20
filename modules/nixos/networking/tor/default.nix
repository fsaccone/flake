{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.networking.tor = {
    enable = lib.mkEnableOption "Enables Tor daemon as a relay";
    socksProxyPort = lib.mkOption {
      type = lib.types.uniq lib.types.int;
      description = "The local port which the SOCKS proxy listens to.";
    };
  };

  config = lib.mkIf config.modules.networking.tor.enable {
    services.tor = {
      enable = true;
      package = pkgs.tor;

      openFirewall = true;
      enableGeoIP = false;
      client = {
        enable = true;
        socksListenAddress = {
          IsolateDestAddr = true;
          addr = "localhost";
          port = config.modules.networking.tor.socksProxyPort;
        };
      };
      relay = {
        enable = true;
        role = "relay";
      };
    };
  };
}
