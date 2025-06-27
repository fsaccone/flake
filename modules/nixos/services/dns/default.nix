{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.fs.services.dns = {
    enable = lib.mkOption {
      description = "Whether to enable NSD DNS server.";
      default = false;
      type = lib.types.bool;
    };
    directory = lib.mkOption {
      description = "NSD's working directory.";
      default = "/etc/nsd";
      readOnly = true;
      type = lib.types.uniq lib.types.path;
    };
    domain = lib.mkOption {
      description = "The domain to setup DNS for.";
      type = lib.types.uniq lib.types.str;
    };
    isSecondary = lib.mkOption {
      description = "Whether the server is a secondary name server.";
      type = lib.types.uniq lib.types.bool;
    };
    primaryIp = lib.mkOption {
      description = ''
        The IP address of the primary name server. Only needed when isSecondary
        is set to true.
      '';
      type = lib.types.uniq lib.types.str;
    };
    secondaryIp = lib.mkOption {
      description = ''
        The IP address of the secondary name server. Only used when isSecondary
        is set to false.
      '';
      type = lib.types.nullOr lib.types.str;
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

  config = lib.mkIf config.fs.services.dns.enable {
    users = {
      users = {
        nsd = {
          hashedPassword = "!";
          isSystemUser = true;
          group = "nsd";
        };
      };
      groups = {
        nsd = { };
      };
    };

    systemd.services = {
      dns = {
        enable = true;
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        serviceConfig = {
          User = "root";
          Group = "root";
          Type = "simple";
          Restart = "on-failure";
          ExecStart =
            let
              inherit (config.fs.services.dns)
                directory
                domain
                isSecondary
                primaryIp
                records
                secondaryIp
                ;

              zone =
                (
                  records
                  |> builtins.map (
                    {
                      name,
                      ttl,
                      class,
                      type,
                      data,
                    }:
                    let
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
                )
                + "\n"
                |> builtins.toFile domain;

              primaryConfiguration = builtins.toFile "nsd.conf" ''
                zone:
                  name: ${domain}
                  zonefile: ${domain}.zone
                  notify: ${secondaryIp} NOKEY
                  provide-xfr: ${secondaryIp} NOKEY
              '';

              secondaryConfiguration = builtins.toFile "nsd.conf" ''
                zone:
                  name: ${domain}
                  zonefile: ${domain}.zone
                  allow-notify: ${primaryIp} NOKEY
                  request-xfr: ${primaryIp} NOKEY
              '';
            in
            pkgs.writeShellScript "dns.sh" ''
              mkdir -p ${directory}

              cd ${directory}
              ${
                (
                  if isSecondary then
                    ''
                      cp ${secondaryConfiguration} nsd.conf
                    ''
                  else
                    ''
                      cp ${primaryConfiguration} nsd.conf
                      cp ${zone} ${domain}.zone
                    ''
                )
              }

              chmod -R 700 ${directory}
              chown -R nsd:nsd ${directory}

              ${pkgs.nsd}/bin/nsd \
                -d \
                -c nsd.conf \
                -p 53 \
                -t ${directory} \
                -u nsd \
            '';
        };
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [ 53 ];
    };
  };
}
