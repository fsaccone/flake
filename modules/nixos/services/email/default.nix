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
    domain = lib.mkOption {
      description = "The domain to host SMTP for.";
      type = lib.types.uniq lib.types.str;
    };
    users = lib.mkOption {
      description = "For each email user, its password hash.";
      default = { };
      type = lib.types.attrsOf lib.types.str;
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
            user: hashedPassword: {
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
                confFiles = pkgs.stdenv.mkDerivation {
                  name = "dovecot-conf-files";
                  buildCommand =
                    let
                      inherit (config.fs.services.email) tls;

                      ssl = builtins.toFile "10-ssl.conf" ''
                        ssl = required
                        ssl_cert = <${tls.certificate}
                        ssl_key = <${tls.key}
                      '';
                    in
                    ''
                      mkdir -p $out/conf.d

                      cp -r \
                        ${pkgs.dovecot}/share/doc/dovecot/example-config/conf.d/* \
                        $out/conf.d
                      chmod -R +w $out/conf.d

                      cp ${ssl} $out/conf.d/10-ssl.conf
                    '';
                };

                configuration = pkgs.writeText "dovecot.conf" ''
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

                  !include ${confFiles}/conf.d/*.conf
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
                tls
                users
                ;

              credentials =
                users
                |> builtins.mapAttrs (name: hash: "${name} ${hash}")
                |> builtins.attrValues
                |> builtins.concatStringsSep "\n"
                |> builtins.toFile "credentials";

              configuration = pkgs.writeText "smtpd.conf" ''
                pki default cert "${tls.certificate}"
                pki default key "${tls.key}"

                table credentials file:${credentials}

                filter check-rdns phase connect \
                  match !rdns disconnect "no rDNS"
                filter check-fcrdns phase connect \
                  match !fcrdns disconnect "no FCrDNS"
                filter dkimsign proc-exec \
                  "${pkgs.opensmtpd-filter-dkimsign}/libexec/opensmtpd/filter-dkimsign \
                     -a rsa-sha256 -t -d ${domain} -s default \
                     -k ${dkimDirectory}/default.key"

                action in maildir junk
                action out relay

                match from any for domain ${domain} action in
                match from auth for any action out

                listen on 0.0.0.0 smtps pki default auth <credentials> \
                  filter { check-rdns, check-fcrdns, dkimsign }
                listen on :: smtps verify pki default auth <credentials> \
                  filter { check-rdns, check-fcrdns, dkimsign }

                listen on 0.0.0.0 tls pki default \
                  filter { check-rdns, check-fcrdns, dkimsign }
                listen on :: tls pki default \
                  filter { check-rdns, check-fcrdns, dkimsign }

                listen on 0.0.0.0 port 587 tls-require pki default \
                  auth <credentials> filter dkimsign
                listen on :: port 587 tls-require pki default \
                  auth <credentials> filter dkimsign
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
      143
      465
      587
      993
    ];
  };
}
