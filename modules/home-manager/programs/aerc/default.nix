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
    accounts = lib.mkOption {
      description = "The list of account configurations.";
      default = { };
      type =
        lib.types.submodule {
          options = {
            address = lib.mkOption {
              description = "The email address.";
              type = lib.types.uniq lib.types.str;
            };
            realName = lib.mkOption {
              description = "The name used as recipient.";
              type = lib.types.uniq lib.types.str;
            };
            imapHost = lib.mkOption {
              description = ''
                The IMAP server name. This is not used if useSsh is set to
                true.
              '';
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
            gpgEncryptedImapPassword = lib.mkOption {
              description = ''
                The GPG encrypted password to access IMAP. This is not used if
                useSsh is set to true.
              '';
              type = lib.types.uniq lib.types.path;
            };
            gpgEncryptedSmtpPassword = lib.mkOption {
              description = ''
                The GPG encrypted password to access SMTP. This is not used if
                useSsh is set to true.
              '';
              type = lib.types.uniq lib.types.path;
            };
            useSsh = lib.mkOption {
              description = ''
                Whether SSH is used as the operation method without the use
                of IMAP, using sendmail on the mail server instead.
              '';
              type = lib.types.uniq lib.types.bool;
            };
            folders = {
              archive = lib.mkOption {
                description = "The archive folder. The default is 'Archive'.";
                default = "Archive";
                type = lib.types.uniq lib.types.str;
              };
              sent = lib.mkOption {
                description = "The sent folder. The default is 'Sent'.";
                default = "Sent";
                type = lib.types.uniq lib.types.str;
              };
              inbox = lib.mkOption {
                description = "The inbox folder. The default is 'Inbox'.";
                default = "Inbox";
                type = lib.types.uniq lib.types.str;
              };
              drafts = lib.mkOption {
                description = "The drafts folder. The default is 'Drafts'.";
                default = "Drafts";
                type = lib.types.uniq lib.types.str;
              };
            };
          };
        }
        |> lib.types.listOf;
    };
  };

  config = lib.mkIf config.fs.programs.aerc.enable {
    home = {
      packages = [ pkgs.aerc ];
      file = {
        ".config/aerc/aerc.conf".text = ''
          [compose]
          editor = ${pkgs.busybox}/bin/vi

          [filters]
          text/html = ${pkgs.html2text}/bin/html2text -utf8 -links
          text/plain = fold -sw 80

          [general]
          unsafe-accounts-conf = true

          [viewer]
          pager = ${pkgs.less}/bin/less --clear-screen
        '';

        ".config/aerc/accounts.conf".text =
          config.fs.programs.aerc.accounts
          |> builtins.map (
            {
              address,
              realName,
              imapHost,
              smtpHost,
              username,
              gpgEncryptedImapPassword,
              gpgEncryptedSmtpPassword,
              useSsh,
              folders,
            }:
            let
              inherit (config.fs.programs) gpg;

              retrieve = pkgs.writeShellScript "retrieve.sh" ''
                mkdir -p ~/mail/${address}/${folders.archive}/cur
                mkdir -p ~/mail/${address}/${folders.archive}/new
                mkdir -p ~/mail/${address}/${folders.archive}/tmp
                mkdir -p ~/mail/${address}/${folders.drafts}/cur
                mkdir -p ~/mail/${address}/${folders.drafts}/new
                mkdir -p ~/mail/${address}/${folders.drafts}/tmp
                mkdir -p ~/mail/${address}/${folders.inbox}/cur
                mkdir -p ~/mail/${address}/${folders.inbox}/new
                mkdir -p ~/mail/${address}/${folders.inbox}/tmp
                mkdir -p ~/mail/${address}/${folders.sent}/cur
                mkdir -p ~/mail/${address}/${folders.sent}/new
                mkdir -p ~/mail/${address}/${folders.sent}/tmp

                ${pkgs.rsync}/bin/rsync -rz \
                  --remove-source-files \
                  --ignore-missing-args \
                  ${username}@${smtpHost}:~/* \
                  ~/mail/${address}/Inbox
              '';

              sendmailCommandBase = builtins.concatStringsSep " " [
                "${pkgs.openssh}/bin/ssh"
                "${username}@${smtpHost}"
                "sendmail"
              ];
            in
            ''
              [${address}]
              from = ${realName} <${address}>

              archive = ${folders.archive}
              copy-to = ${folders.sent}
              default = ${folders.inbox}
              postpone = ${folders.drafts}
            ''
            + (
              if useSsh then
                ''
                  check-mail = 10s
                  check-mail-cmd = ${retrieve}
                  check-mail-timeout = 30s
                  source = maildir://~/mail/${address}

                  outgoing = ${sendmailCommandBase}
                ''
              else if gpg.enable then
                ''
                  source = imaps://${username}@${imapHost}
                  source-cred-cmd = ${pkgs.gnupg}/bin/gpg \
                                    -r ${gpg.primaryKey.fingerprint} \
                                    -d ${gpgEncryptedImapPassword}

                  outgoing = smtps://${username}@${smtpHost}
                  outgoing-cred-cmd = ${pkgs.gnupg}/bin/gpg \
                                      -r ${gpg.primaryKey.fingerprint} \
                                      -d ${gpgEncryptedSmtpPassword}
                ''
              else
                ""
            )
            + (
              if gpg.enable then
                ''
                  pgp-auto-sign = true
                  pgp-key-id = ${gpg.primaryKey.fingerprint}
                  pgp-opportunistic-encrypt = false
                ''
              else
                ""
            )
          )
          |> builtins.concatStringsSep "\n";
      };
    };
  };
}
