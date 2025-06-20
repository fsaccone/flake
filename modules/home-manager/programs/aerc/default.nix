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
      folders = {
        drafts = lib.mkOption {
          description = "The drafts folder.";
          type = lib.types.uniq lib.types.str;
        };
        inbox = lib.mkOption {
          description = "The inbox folder.";
          type = lib.types.uniq lib.types.str;
        };
        sent = lib.mkOption {
          description = "The sent folder.";
          type = lib.types.uniq lib.types.str;
        };
        trash = lib.mkOption {
          description = "The spam folder.";
          type = lib.types.uniq lib.types.str;
        };
      };
      imapHost = lib.mkOption {
        description = "The IMAP server name.";
        type = lib.types.uniq lib.types.str;
      };
      imapTlsPort = lib.mkOption {
        description = "The IMAP port. If null then the default port is used.";
        type = lib.types.nullOr lib.types.int;
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
      smtpTlsPort = lib.mkOption {
        description = "The SMTP port. If null then the default port is used.";
        type = lib.types.nullOr lib.types.int;
      };
      username = lib.mkOption {
        description = "The username used to login to the email account.";
        type = lib.types.uniq lib.types.str;
      };
    };
  };

  config = lib.mkIf config.fs.programs.aerc.enable {
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
        aerc.enable = true;

        passwordCommand = "${config.fs.programs.aerc.email.passwordScript}";

        inherit (config.fs.programs.aerc.email) address folders realName;

        flavor = "plain";
        gpg = lib.mkIf config.fs.programs.gpg.enable {
          key = config.fs.programs.gpg.primaryKey.fingerprint;
          signByDefault = true;
        };
        imap = {
          host = config.fs.programs.aerc.email.imapHost;
          port = config.fs.programs.aerc.email.imapTlsPort;
          tls = {
            enable = true;
            useStartTls = false;
          };
        };
        primary = true;
        smtp = {
          host = config.fs.programs.aerc.email.smtpHost;
          port = config.fs.programs.aerc.email.smtpTlsPort;
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
