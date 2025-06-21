{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.fs.services.email = {
    enable = lib.mkOption {
      description = "Whether to enable a OpenSMTPD SMTP.";
      default = false;
      type = lib.types.bool;
    };
    dkimDirectory = lib.mkOption {
      description = ''
        The directory that will contain the generated DKIM private key
        'default.key' and public key 'default.pub'. The DKIM selector
        is 'default'.
      '';
      default = "/etc/dkim";
      readOnly = true;
      type = lib.types.uniq lib.types.path;
    };
    host = {
      domain = lib.mkOption {
        description = "The domain of the server.";
        type = lib.types.uniq lib.types.str;
      };
      ipv4 = lib.mkOption {
        description = "The IPv4 of the server.";
        type = lib.types.uniq lib.types.str;
      };
      ipv6 = lib.mkOption {
        description = "The IPv6 of the server.";
        type = lib.types.uniq lib.types.str;
      };
    };
    domain = lib.mkOption {
      description = "The domain to host SMTP for.";
      type = lib.types.uniq lib.types.str;
    };
    users = lib.mkOption {
      description = "For each email user, its configuration.";
      default = { };
      type =
        lib.types.submodule {
          options = {
            sshKeys = lib.mkOption {
              description = "The public SSH keys used for authentication.";
              default = [ ];
              type = lib.types.listOf lib.types.path;
            };
            aliases = lib.mkOption {
              description = "The list of alternative usernames of the user.";
              default = [ ];
              type = lib.types.listOf lib.types.str;
            };
          };
        }
        |> lib.types.attrsOf;
    };
    tls = {
      certificate = lib.mkOption {
        description = "The path to the TLS certificate file.";
        type = lib.types.uniq lib.types.path;
      };
      key = lib.mkOption {
        description = "The path to the TLS key file.";
        type = lib.types.uniq lib.types.path;
      };
    };
  };

  config = lib.mkIf config.fs.services.email.enable {
    users = {
      users =
        (
          config.fs.services.email.users
          |> builtins.mapAttrs (
            user:
            { sshKeys, ... }:
            {
              hashedPassword = "!";
              isNormalUser = true;
              group = "smtpq";
              createHome = true;
              home = "/home/${user}";
              openssh.authorizedKeys.keyFiles = sshKeys;
              packages = [
                pkgs.rsync
                pkgs.system-sendmail
              ];
            }
          )
        )
        // {
          smtpd = {
            hashedPassword = "!";
            isSystemUser = true;
            group = "smtpd";
          };
          smtpq = {
            hashedPassword = "!";
            isSystemUser = true;
            group = "smtpq";
          };
        };
      groups = {
        smtpd = { };
        smtpq = { };
      };
    };

    environment.systemPackages = [ pkgs.opensmtpd ];

    systemd = {
      services = {
        dkim = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            User = "root";
            Group = "root";
            Type = "oneshot";
            ExecStart =
              let
                inherit (config.fs.services.email) dkimDirectory;
              in
              pkgs.writeShellScript "dkim" ''
                mkdir -p ${dkimDirectory}

                if [ ! -f "${dkimDirectory}/default.key" ]; then
                  ${pkgs.openssl}/bin/openssl genrsa \
                    -out ${dkimDirectory}/default.key \
                    4096

                  chown smtpd:smtpd ${dkimDirectory}/default.key

                  echo "DKIM private key generated.";
                fi

                if [ ! -f "${dkimDirectory}/default.pub" ]; then
                  ${pkgs.openssl}/bin/openssl rsa \
                    -in ${dkimDirectory}/default.key \
                    -pubout \
                    -out ${dkimDirectory}/default.pub

                  echo "DKIM public key generated.";
                fi
              '';
          };
        };
        smtp = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          after = [
            "network.target"
            "dkim.service"
            "acme.service"
          ];
          serviceConfig =
            let
              inherit (config.fs.services.email)
                dkimDirectory
                domain
                host
                tls
                users
                ;

              aliases =
                users
                |> builtins.mapAttrs (
                  name:
                  { aliases, ... }:
                  builtins.map (alias: ''
                    ${alias}@${domain} ${name}
                    ${alias}@${host.ipv4} ${name}
                    ${alias}@${host.ipv6} ${name}
                  '') aliases
                  |> builtins.concatStringsSep "\n"
                )
                |> builtins.attrValues
                |> builtins.concatStringsSep "\n"
                |> builtins.toFile "aliases";

              addresses =
                users
                |> builtins.mapAttrs (
                  name:
                  { aliases, ... }:
                  let
                    aliasAddresses =
                      aliases
                      |> builtins.map (alias: ''
                        ${alias}@${domain}
                        ${alias}@${host.ipv4}
                        ${alias}@${host.ipv6}
                      '')
                      |> builtins.concatStringsSep "\n";
                  in
                  ''
                    ${name}@${domain}
                    ${name}@${host.ipv4}
                    ${name}@${host.ipv6}
                    ${aliasAddresses}
                  ''
                )
                |> builtins.attrValues
                |> builtins.concatStringsSep "\n"
                |> builtins.toFile "addresses";

              configuration = pkgs.writeText "smtpd.conf" ''
                pki default cert "${tls.certificate}"
                pki default key "${tls.key}"

                table aliases file:${aliases}
                table addresses file:${addresses}

                filter check-rdns phase connect \
                  match !rdns disconnect "no rDNS"
                filter check-fcrdns phase connect \
                  match !fcrdns disconnect "no FCrDNS"
                filter dkimsign proc-exec \
                  "${pkgs.opensmtpd-filter-dkimsign}/libexec/opensmtpd/filter-dkimsign \
                     -a rsa-sha256 -t -d ${domain} -s default \
                     -k ${dkimDirectory}/default.key"

                action in maildir junk alias <aliases>
                action out relay helo ${host.domain}

                match from any for rcpt-to <addresses> action in
                match from auth for any action out

                listen on 0.0.0.0 smtps pki default hostname ${host.domain} \
                  auth filter { check-rdns, check-fcrdns, dkimsign }
                listen on :: smtps pki default hostname ${host.domain} \
                  auth filter { check-rdns, check-fcrdns, dkimsign }

                listen on 0.0.0.0 tls pki default hostname ${host.domain} \
                  filter { check-rdns, check-fcrdns, dkimsign }
                listen on :: tls pki default hostname ${host.domain} \
                  filter { check-rdns, check-fcrdns, dkimsign }

                listen on 0.0.0.0 port 587 tls-require pki default \
                  hostname ${host.domain} auth filter dkimsign
                listen on :: port 587 tls-require pki default \
                  hostname ${host.domain} auth filter dkimsign
              '';
            in
            {
              User = "root";
              Group = "root";
              Restart = "on-failure";
              Type = "simple";
              ExecStart = pkgs.writeShellScript "smtp" ''
                ${pkgs.opensmtpd}/bin/smtpd -dvf ${configuration}
              '';
            };
        };
      };
    };

    networking.firewall.allowedTCPPorts = [
      25
      465
      587
    ];
  };
}
