{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules = {
    aerc = {
      enable = lib.mkEnableOption "Enables aerc";
      email = {
        address = lib.mkOption {
          type = lib.types.uniq lib.types.str;
          description = ''
            The email address.
          '';
        };
        folders = {
          drafts = lib.mkOption {
            type = lib.types.uniq lib.types.str;
            description = ''
              The drafts folder.
            '';
          };
          inbox = lib.mkOption {
            type = lib.types.uniq lib.types.str;
            description = ''
              The inbox folder.
            '';
          };
          sent = lib.mkOption {
            type = lib.types.uniq lib.types.str;
            description = ''
              The sent folder.
            '';
          };
          trash = lib.mkOption {
            type = lib.types.uniq lib.types.str;
            description = ''
              The spam folder.
            '';
          };
        };
        imapHost = lib.mkOption {
          type = lib.types.uniq lib.types.str;
          description = ''
            The IMAP server name.
          '';
        };
        imapTlsPort = lib.mkOption {
          type = lib.types.nullOr lib.types.int;
          description = ''
            The IMAP port. If null then the default port is used.
          '';
        };
        passwordCommand = lib.mkOption {
          type = lib.types.uniq lib.types.str;
          description = ''
            The command which returns the password to login to the email account.
          '';
        };
        realName = lib.mkOption {
          type = lib.types.uniq lib.types.str;
          description = ''
            The name given to the email account and used as recipient.
          '';
        };
        signature = lib.mkOption {
          type = lib.types.uniq lib.types.str;
          description = ''
            The signature appended by default to the end of sent emails, after a "---" line.
          '';
        };
        smtpHost = lib.mkOption {
          type = lib.types.uniq lib.types.str;
          description = ''
            The SMTP server name.
          '';
        };
        smtpTlsPort = lib.mkOption {
          type = lib.types.nullOr lib.types.int;
          description = ''
            The SMTP port. If null then the default port is used.
          '';
        };
        username = lib.mkOption {
          type = lib.types.uniq lib.types.str;
          description = ''
            The username used to login to the email account.
          '';
        };
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
      };
    };

    accounts.email = {
      accounts.${config.modules.aerc.email.realName} = {
        aerc = {
          enable = true;
        };

        inherit (config.modules.aerc.email) address folders passwordCommand realName;

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
        msmtp.enable = true;
        primary = true;
        signature = {
          delimiter = ''
            --
          '';
          showSignature = "append";
          text = config.modules.aerc.email.signature;
        };
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
