{
  lib,
  options,
  config,
  ...
}:
{
  options.modules.tor = {
    enable = lib.mkOption {
      description = "Whether to enable Tor.";
      default = false;
      type = lib.types.bool;
    };
    services = lib.mkOption {
      description = "For each onion service name, its configuration.";
      default = [ ];
      type =
        lib.types.submodule {
          options = {
            ports = lib.mkOption {
              description = "The ports to make avaiable.";
              type = lib.types.listOf lib.types.int;
            };
          };
        }
        |> lib.types.attrsOf;
    };
    servicesDirectory = lib.mkOption {
      description = ''
        The directory where the each service configuration will reside.
      '';
      default = "/var/lib/tor/onion";
      readOnly = true;
      type = lib.types.uniq lib.types.path;
    };
  };

  config = lib.mkIf config.modules.tor.enable {
    services.tor = {
      enable = true;
      enableGeoIP = false;
      openFirewall = false;
      settings = {
        ClientUseIPv4 = true;
        ClientUseIPv6 = true;
      };
      relay = {
        enable = true;
        role = "relay";
        onionServices =
          config.modules.tor.services
          |> builtins.mapAttrs (
            name:
            { ports }:
            {
              version = 3;
              path = "${config.modules.tor.servicesDirectory}/${name}";
              map =
                ports
                |> builtins.map (port: {
                  inherit port;
                  target = {
                    addr = "localhost";
                    inherit port;
                  };
                });
            }
          );
      };
    };
  };
}
