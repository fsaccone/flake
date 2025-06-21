{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.fs.programs.aerc = {
    enable = lib.mkOption {
      description = "Whether to enable aerc.";
      default = false;
      type = lib.types.bool;
    };
    email = {
      address = lib.mkOption {
        description = "The email address.";
        type = lib.types.uniq lib.types.str;
      };
      popHost = lib.mkOption {
        description = "The POP3 server name.";
        type = lib.types.uniq lib.types.str;
      };
      passwordScript = lib.mkOption {
        description = ''
          The script which returns the password to login to the email
          account.
        '';
        type = lib.types.uniq lib.types.path;
      };
      realName = lib.mkOption {
        description = "The name used as recipient.";
        type = lib.types.uniq lib.types.str;
      };
      smtpHost = lib.mkOption {
        description = "The SMTP server name.";
        type = lib.types.uniq lib.types.str;
      };
      username = lib.mkOption {
        description = "The username used to login to the email account.";
        type = lib.types.uniq lib.types.str;
      };
    };
  };

  config = lib.mkIf config.fs.programs.aerc.enable {
    home.activation.createMaildir = ''
      mkdir -p ~/mail/{cur,new,tmp}
    '';

    programs.aerc = {
      enable = true;
      package = pkgs.aerc;

      extraConfig = {
        general = {
          unsafe-accounts-conf = true;
        };
        viewer.pager = "${pkgs.less}/bin/less --clear-screen";
        compose.editor = "${pkgs.nano}/bin/nano";
        filters = {
          "text/plain" = "fold -sw 80";
          "text/html" = "${pkgs.html2text}/bin/html2text -utf8 -links";
        };
      };
    };

    accounts.email = {
      accounts.${config.fs.programs.aerc.email.address} = {
        aerc = {
          enable = true;
          extraAccounts =
            let
              inherit (config.fs.programs.aerc.email) passwordScript popHost username;

              mpop = pkgs.writeShellScriptBin "mpop" ''
                mkdir -p ~/mail/{cur,new,tmp}

                ${pkgs.mpop}/bin/mpop \
                  --host=${popHost} \
                  --port=995 \
                  --user=${username} \
                  --passwordeval='${passwordScript}' \
                  --tls=on \
                  --delivery=maildir,~/mail
              '';
            in
            {
              check-mail-cmd = "${mpop}/bin/mpop";
              check-mail-timeout = "10s";
              source = "maildir://~/mail";
            };
        };

        passwordCommand = "${config.fs.programs.aerc.email.passwordScript}";

        inherit (config.fs.programs.aerc.email) address realName;

        flavor = "plain";
        gpg = lib.mkIf config.fs.programs.gpg.enable {
          key = config.fs.programs.gpg.primaryKey.fingerprint;
          signByDefault = true;
        };
        primary = true;
        smtp = {
          host = config.fs.programs.aerc.email.smtpHost;
          port = 465;
          tls = {
            enable = true;
            useStartTls = false;
          };
        };
        userName = config.fs.programs.aerc.email.username;
      };
    };
  };
}
