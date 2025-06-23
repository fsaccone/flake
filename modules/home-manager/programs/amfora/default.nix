{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.fs.programs.amfora = {
    enable = lib.mkOption {
      description = "Whether to enable Amfora.";
      default = false;
      type = lib.types.bool;
    };
    certificates = lib.mkOption {
      description = "The list of client certificates configurations per host.";
      default = [ ];
      type =
        lib.types.submodule {
          options = {
            host = lib.mkOption {
              description = ''
                The domain name where the client certificate is used.
              '';
              type = lib.types.uniq lib.types.str;
            };
            certificate = lib.mkOption {
              description = "The certificate file.";
              type = lib.types.uniq lib.types.path;
            };
            gpgEncryptedKey = lib.mkOption {
              description = ''
                The key file, GPG encryped with the primary key specified in
                the GPG module.
              '';
              type = lib.types.uniq lib.types.path;
            };
          };
        }
        |> lib.types.listOf;
    };
  };

  config = lib.mkIf config.fs.programs.amfora.enable {
    home = {
      packages = [ pkgs.amfora ];
      shellAliases =
        let
          inherit (config.fs.programs) gpg;
          inherit (config.fs.programs.amfora) certificates;
          certificatesIsEmpty = builtins.length certificates == 0;
        in
        lib.mkIf (gpg.enable && !certificatesIsEmpty) {
          "amfora" =
            let
              decryptKeys =
                certificates
                |> builtins.map (
                  {
                    host,
                    certificate,
                    gpgEncryptedKey,
                  }:
                  let
                    output = "~/.cache/amfora/keys/${host}";
                  in
                  ''
                    mkdir -p ${builtins.dirOf output}

                    ${pkgs.gnupg}/bin/gpg -r "${gpg.primaryKey.fingerprint}" \
                    -d ${gpgEncryptedKey} > ${output}
                  ''
                )
                |> builtins.concatStringsSep "\n"
                |> pkgs.writeShellScriptBin "decrypt-keys";
            in
            "${decryptKeys}/bin/decrypt-keys && ${pkgs.amfora}/bin/amfora";
        };
      file =
        let
          authSection =
            let
              certs =
                config.fs.programs.amfora.certificates
                |> builtins.map (
                  { host, certificate, ... }:
                  ''
                    "${host}" = '${certificate}'
                  ''
                )
                |> builtins.concatStringsSep "\n";
              keys =
                config.fs.programs.amfora.certificates
                |> builtins.map (
                  { host, ... }:
                  ''
                    "${host}" = '~/.cache/amfora/keys/${host}'
                  ''
                )
                |> builtins.concatStringsSep "\n";
            in
            if config.fs.programs.gpg.enable then
              ''
                [auth]
                [auth.certs]
                ${certs}

                [auth.keys]
                ${keys}
              ''
            else
              lib.warn ''
                Since the GPG module was not enabled, the client certificates
                were not enabled for Anfora.
              '' "";
        in
        {
          ".config/amfora/config.toml".text = ''
            ${authSection}

            [a-general]
            home = "gemini://geminiprotocol.net"
            auto_redirect = false
            http = [ '${pkgs.ladybird}/bin/Ladybird' ]
            search = "gemini://tlgs.one/search"
            color = true
            ansi = true
            highlight_code = true
            highlight_style = "monokai"
            bullets = true
            show_link = false
            max_width = 80
            downloads = '~/downloads'
            page_max_size = 2097152 # 2 MiB
            page_max_time = 10 # seconds
            scrollbar = "auto"
            underline = true

            [keybindings]
            bind_search = "/"
            bind_next_match = "n"
            bind_prev_match = "N"

            [url-handlers]
            other = 'default'

            [url-prompts]
            other = true
            gemini = false

            [cache]
            max_size = 0
            max_pages = 30
            timeout = 1800 # 30 mins

            [subscriptions]
            popup = true
            update_interval = 1800 # 30 mins
            workers = 10
            entries_per_page = 20
            header = false
          '';
        };
    };
  };
}
