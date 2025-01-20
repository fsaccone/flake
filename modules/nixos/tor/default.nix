{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.tor = {
    enable = lib.mkEnableOption "Enables Tor daemon";
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
          port = 9050;
        };
      };
      relay = {
        enable = true;
        role = "relay";
      };
    };
  };
}
