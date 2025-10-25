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
          };
        }
        |> lib.types.listOf;
    };
  };

  config = lib.mkIf config.fs.programs.aerc.enable {
    home = {
      packages =
        let
          inherit (config.fs.programs) gpg;
        in
        [
          (
            if gpg.enable then
              pkgs.writeShellScriptBin "aerc" ''
                set -e

                no_gpg=0

                while getopts "n" opt; do
                  case $opt in
                    n)
                      no_gpg=1
                      ;;
                    *)
                      echo "Usage: $0 [-n]"
                      echo "    -n"
                      echo "      Do not prompt to unlock the GPG key."
                      exit 1
                      ;;
                  esac
                done

                if [ $no_gpg -eq 0 ]; then
                  export GPG_TTY=$(tty)

                  echo "Successfully unlocked the GPG key." \
                  | ${pkgs.gnupg}/bin/gpg -qer ${gpg.primaryKey.fingerprint} \
                  | ${pkgs.gnupg}/bin/gpg -qd
                fi

                ${pkgs.aerc}/bin/aerc
              ''
            else
              pkgs.aerc
          )
        ];
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
            }:
            let
              inherit (config.fs.programs) gpg;

              retrieve = pkgs.writeShellScript "retrieve.sh" ''
                mkdir -p \
                  ~/mail/${address}/{Archive,Drafts,Inbox,Sent}/{cur,new,tmp}

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

              archive = Archive
              copy-to = Sent
              default = Inbox
              postpone = Drafts
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
