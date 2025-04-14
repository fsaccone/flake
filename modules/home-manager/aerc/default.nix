{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.aerc = {
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
      passwordCommand = lib.mkOption {
        description = ''
          The command which returns the password to login to the email
          account.
        '';
        type = lib.types.uniq lib.types.str;
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

  config = lib.mkIf config.modules.aerc.enable {
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
          "text/plain" = "${pkgs.ccze}/bin/ccze --mode=ansi --raw-ansi";
          "text/html" = "${pkgs.pandoc}/bin/pandoc -f html -t plain";
        };
      };
    };

    accounts.email = {
      accounts.${config.modules.aerc.email.address} = {
        aerc.enable = true;

        inherit (config.modules.aerc.email)
          address
          folders
          passwordCommand
          realName
          ;

        flavor = "plain";
        gpg = lib.mkIf config.modules.gpg.enable {
          key = config.modules.gpg.primaryKey.fingerprint;
          signByDefault = true;
        };
        imap = {
          host = config.modules.aerc.email.imapHost;
          port = config.modules.aerc.email.imapTlsPort;
          tls = {
            enable = true;
            useStartTls = false;
          };
        };
        primary = true;
        smtp = {
          host = config.modules.aerc.email.smtpHost;
          port = config.modules.aerc.email.smtpTlsPort;
          tls = {
            enable = true;
            useStartTls = false;
          };
        };
        userName = config.modules.aerc.email.username;
      };
    };
  };
}
