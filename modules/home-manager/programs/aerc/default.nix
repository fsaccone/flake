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
    home = {
      activation.createMaildir = ''
        mkdir -p ~/mail/{cur,new,tmp}
      '';
      packages = [ pkgs.aerc ];
      file = {
        ".config/aerc/aerc.conf".text = ''
          [compose]
          editor = ${pkgs.nano}/bin/nano

          [filters]
          text/html = ${pkgs.html2text}/bin/html2text -utf8 -links
          text/plain = fold -sw 80

          [general]
          unsafe-accounts-conf = true

          [viewer]
          pager = ${pkgs.less}/bin/less --clear-screen
        '';

        ".config/aerc/accounts.conf".text =
          let
            inherit (config.fs.programs.aerc.email)
              address
              realName
              smtpHost
              username
              ;

            inherit (config.fs.programs) gpg;

            retrieve = pkgs.writeShellScript "retrieve" ''
              mkdir -p ~/mail

              ${pkgs.rsync}/bin/rsync -rz \
                --remove-source-files \
                ${username}@${smtpHost}:~/* \
                ~/mail
            '';

            sendmailCommandBase = builtins.concatStringsSep " " [
              "${pkgs.openssh}/bin/ssh"
              "${username}@${smtpHost}"
              "sendmail"
              "-v"
              "-F \"${realName}\""
              "-f ${address}"
            ];
          in
          ''
            [${address}]
            from = ${realName} <${address}>

            archive = Archive
            copy-to = Sent
            default = Inbox
            postpone = Drafts

            check-mail = 10s
            check-mail-cmd = ${retrieve}
            check-mail-timeout = 30s
            source = maildir://~/mail

            outgoing = ${sendmailCommandBase}
          ''
          + (
            if gpg.enable then
              ''
                pgp-auto-sign = true
                pgp-key-id = ${gpg.primaryKey.fingerprint}
                pgp-opportunistic-encrypt = false
              ''
            else
              ""
          );
      };
    };
  };
}
