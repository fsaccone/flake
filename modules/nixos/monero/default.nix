{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.monero = {
    enable = lib.mkOption {
      description = "Whether to enable Monero.";
      default = false;
      type = lib.types.bool;
    };
    mining = {
      enable = lib.mkOption {
        description = "Whether to mine monero.";
        default = false;
        type = lib.types.bool;
      };
      address = lib.mkOption {
        description = "The address where rewards are sent.";
        type = lib.types.uniq lib.types.str;
      };
    };
  };

  config = lib.mkIf config.modules.monero.enable {
    users = {
      users = {
        monero = {
          hashedPassword = "!";
          isSystemUser = true;
          group = "monero";
          createHome = true;
          home = "/var/lib/monero";
        };
      };
      groups = {
        monero = { };
      };
    };

    environment.systemPackages = [ pkgs.monero-cli ];

    services.monero = {
      enable = true;
      dataDir = "/var/lib/monero";
      rpc = {
        user = "monero";
        port = 18081;
      };
      mining = {
        inherit (config.modules.monero.mining) enable address;
        threads = 0;
      };
    };

    networking.firewall.allowedTCPPorts = [ 18081 ];
  };
}
