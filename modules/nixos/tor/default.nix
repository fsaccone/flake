{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.tor = {
    enable = lib.mkEnableOption "Enables Tor daemon as a relay";
    socksProxyPort = lib.mkOption {
      type = lib.types.uniq lib.types.int;
      description = "The local port which the SOCKS proxy listens to.";
    };
  };

  config = lib.mkIf config.modules.tor.enable {
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
          port = config.modules.tor.socksProxyPort;
        };
      };
      relay = {
        enable = true;
        role = "relay";
      };
    };
  };
}
