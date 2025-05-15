{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.services.bind = {
    enable = lib.mkOption {
      description = "Whether to enable BIND.";
      default = false;
      type = lib.types.bool;
    };
    domain = lib.mkOption {
      description = "The domain to setup DNS for.";
      type = lib.types.uniq lib.types.str;
    };
    records = lib.mkOption {
      description = "The DNS records.";
      default = [ ];
      type =
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              description = "The name of the record.";
              type = lib.types.uniq lib.types.str;
            };
            ttl = lib.mkOption {
              description = "The TTL of the record.";
              type = lib.types.uniq lib.types.int;
            };
            class = lib.mkOption {
              description = "The class of the record.";
              type = lib.types.uniq lib.types.str;
            };
            type = lib.mkOption {
              description = "The type of the record.";
              type = lib.types.uniq lib.types.str;
            };
            data = lib.mkOption {
              description = "The data of the record.";
              type = lib.types.uniq lib.types.str;
            };
          };
        }
        |> lib.types.listOf;
    };
  };

  config = lib.mkIf config.services.bind.enable {
    services.bind = {
      enable = true;
      package = pkgs.bind;

      zones.${config.services.bind.domain} = {
        master = true;
        file =
          config.services.bind.records
          |> builtins.map (
            {
              name,
              ttl,
              class,
              type,
              data,
            }:
            let
              inherit (config.services.bind) domain;
              subdomain = if name != "@" then "${name}." else "";
            in
            [
              "${subdomain}${domain}."
              (builtins.toString ttl)
              class
              type
              data
            ]
            |> builtins.concatStringsSep " "
          )
          |> builtins.concatStringsSep "\n"
          |> pkgs.writeText "${config.services.bind.domain}";
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [ 53 ];
    };
  };
}
