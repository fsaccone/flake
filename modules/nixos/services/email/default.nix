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
      description = ''
        Whether to enable a OpenSMTPD SMTP server and a Dovecot IMAP server.
      '';
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
    hostDomain = lib.mkOption {
      description = "The domain of the server.";
      type = lib.types.uniq lib.types.str;
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
            hashedPassword = lib.mkOption {
              description = "The password hash.";
              type = lib.types.uniq lib.types.str;
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
            { hashedPassword, ... }:
            {
              inherit hashedPassword;
              isSystemUser = true;
              group = "email";
              createHome = true;
              home = "/home/${user}";
            }
          )
        )
        // {
          dovecot = {
            hashedPassword = "!";
            isSystemUser = true;
            group = "dovecot";
          };
          dovenull = {
            hashedPassword = "!";
            isSystemUser = true;
            group = "dovenull";
          };
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
        dovecot = { };
        dovenull = { };
        email = { };
        smtpd = { };
        smtpq = { };
      };
    };

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
        imap = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          after = [
            "network.target"
            "dkim.service"
            "acme.service"
          ];
          serviceConfig = {
            User = "root";
            Group = "root";
            Type = "simple";
            Restart = "on-failure";
            ExecStart =
              let
                inherit (config.fs.services.email) tls;

                configuration = pkgs.writeText "dovecot.conf" ''
                  ssl = required
                  ssl_cert = <${tls.certificate}
                  ssl_key = <${tls.key}

                  protocols = imap
                  listen = *, ::

                  default_login_user = dovenull
                  default_internal_user = dovecot

                  userdb {
                    driver = passwd
                  }

                  passdb {
                    driver = pam
                    args = failure_show_msg=yes dovecot
                  }

                  disable_plaintext_auth = yes

                  service imap-login {
                    inet_listener imaps {
                      port = 993
                      ssl = yes
                    }

                    service_count = 1
                  }

                  imap_hibernate_timeout = 1h

                  namespace inbox {
                    inbox = yes
                    mailbox Archive {
                      auto = create
                      special_use = \Archive
                    }
                    mailbox Drafts {
                      auto = create
                      special_use = \Drafts
                    }
                    mailbox Junk {
                      auto = create
                      special_use = \Junk
                    }
                    mailbox Sent {
                      auto = create
                      special_use = \Sent
                    }
                    mailbox Trash {
                      auto = create
                      special_use = \Trash
                    }
                  }
                '';
              in
              pkgs.writeShellScript "imap" ''
                ${pkgs.dovecot}/bin/dovecot -Fc ${configuration}
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
                hostDomain
                tls
                users
                ;

              credentials =
                users
                |> builtins.mapAttrs (
                  name:
                  { hashedPassword, ... }:
                  ''
                    ${name} ${hashedPassword}
                  ''
                )
                |> builtins.attrValues
                |> builtins.concatStringsSep "\n"
                |> builtins.toFile "credentials";

              aliases =
                users
                |> builtins.mapAttrs (
                  name:
                  { aliases, ... }:
                  builtins.map (alias: ''
                    ${alias} ${name}
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
                  ''
                    ${name}@${domain}
                    ${builtins.concatStringsSep "\n" aliases}@${domain}
                  ''
                )
                |> builtins.attrValues
                |> builtins.concatStringsSep "\n"
                |> builtins.toFile "addresses";

              configuration = pkgs.writeText "smtpd.conf" ''
                pki default cert "${tls.certificate}"
                pki default key "${tls.key}"

                table credentials file:${credentials}
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
                action out relay helo ${hostDomain}

                match from any for rcpt-to <addresses> action in
                match from auth for any action out

                listen on 0.0.0.0 smtps pki default hostname ${hostDomain} \
                  auth <credentials> \
                  filter { check-rdns, check-fcrdns, dkimsign }
                listen on :: smtps pki default hostname ${hostDomain} \
                  auth <credentials> \
                  filter { check-rdns, check-fcrdns, dkimsign }

                listen on 0.0.0.0 tls pki default hostname ${hostDomain} \
                  filter { check-rdns, check-fcrdns, dkimsign }
                listen on :: tls pki default hostname ${hostDomain} \
                  filter { check-rdns, check-fcrdns, dkimsign }

                listen on 0.0.0.0 port 587 tls-require pki default \
                  hostname ${hostDomain} auth <credentials> filter dkimsign
                listen on :: port 587 tls-require pki default \
                  hostname ${hostDomain} auth <credentials> filter dkimsign
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

    security.pam.services = {
      dovecot = { };
    } // builtins.mapAttrs (_: _: { }) config.fs.services.email.users;

    environment.etc."dovecot/modules".source =
      let
        env = pkgs.buildEnv {
          name = "dovecot-modules";
          paths = [ pkgs.dovecot ];
        };
      in
      "${env}/lib/dovecot";

    networking.firewall.allowedTCPPorts = [
      25
      465
      587
      993
    ];
  };
}
