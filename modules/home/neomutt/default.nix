{
  lib,
  options,
  config,
  pkgs,
  inputs,
  ...
}:
{
  options.modules = {
    neomutt.enable = lib.mkEnableOption "Enables NeoMutt";
  };

  config = lib.mkIf config.modules.neomutt.enable {
    programs.neomutt = {
      enable = true;
      package = pkgs.neomutt;

      editor = "${pkgs.neovim}/bin/nvim";
      settings = {
        header_cache = "~/.cache/neomutt";
        message_cachedir = "~/.cache/neomutt";
      };
      sidebar = {
        enable = true;
        format = "%B%?F? [%F]?%* %?N?%N/?%S";
        shortPath = true;
        width = 22;
      };
      vimKeys = true;
    };

    accounts.email = {
      accounts."francesco" = {
        neomutt = {
          enable = true;
          mailboxName = "Inbox";
          mailboxType = "imap";
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
          encryptByDefault = true;
          key = "42616543258F1BD93E84F0DB63A0ED9A00042E8C";
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
        passwordCommand = "";
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
