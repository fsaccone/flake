{
  lib,
  options,
  config,
  pkgs,
  inputs,
  getSecretFile,
  ...
}:
{
  options.modules = {
    aerc.enable = lib.mkEnableOption "Enables aerc";
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
      accounts."Francesco Saccone" = {
        aerc = {
          enable = true;
        };

        address = "francesco@francescosaccone.com";
        flavor = "plain";
        folders = {
          drafts = "Drafts";
          inbox = "INBOX";
          sent = "Sent";
          trash = "Trash";
        };
        gpg = lib.mkIf config.modules.gpg.enable {
          key = config.modules.gpg.primaryKey.fingerprint;
          signByDefault = true;
        };
        imap = {
          host = "mail.privateemail.com";
          port = 993;
          tls = {
            enable = true;
            useStartTls = false;
          };
        };
        msmtp.enable = true;
        passwordCommand = if config.modules.gpg.enable then ''
          ${pkgs.coreutils}/bin/cat ${getSecretFile "email"} | ${pkgs.gnupg}/bin/gpg --decrypt --recipient ${config.modules.gpg.primaryKey.fingerprint}
        '' else lib.warn "GnuPG module not enabled: aerc won't be able to login." "";
        primary = true;
        realName = "Francesco Saccone";
        signature = {
          delimiter = ''
            --
          '';
          showSignature = "append";
          text = ''
            Francesco Saccone
            francescosaccone.com
          '';
        };
        smtp = {
          host = "mail.privateemail.com";
          port = 465;
          tls = {
            enable = true;
            useStartTls = false;
          };
        };
        userName = "francesco%40francescosaccone.com";
      };
    };
  };
}
