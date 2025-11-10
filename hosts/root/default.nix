{
  config,
  pkgs,
  inputs,
  ...
}:
let
  domain = import ./domain.nix;

  site = pkgs.stdenv.mkDerivation {
    name = "site";
    src = inputs.site;

    buildInputs = [
      pkgs.imagemagick
      pkgs.inkscape
      pkgs.lowdown
    ];

    postInstall = ''
      mkdir -p $out/errors
      cp -f 404.html 5xx.html $out/errors
    '';

    makeFlags = [ "HOST=${domain}" ];

    installFlags = [ "PREFIX=$(out)/root" ];
  };

  generateStagitRepository =
    let
      inherit (config.fs.services) http git;
    in
    name:
    pkgs.writeShellScript "generate-stagit.sh" ''
      set -e

      # Create index.html
      mkdir -p ${http.directory}/git
      cd ${http.directory}/git

      ${pkgs.stagit}/bin/stagit-index ${git.directory}/*/ > index.html

      # Symlink favicon.png, logo.png and style.css
      ln -sf ../public/icon32.png favicon.png
      ln -sf ../public/icon32.png logo.png
      ln -sf ../public/stagit.css style.css

      # This is needed because when the script is run one time after
      # the other the copying of the static files brings a "Permission denied"
      # error, since they only have read permission at creation.
      chmod -R u+w .

      echo "Stagit index file generated: <www>/git/index.html".

      # Create repository pages
      mkdir -p ${http.directory}/git/${name}
      cd ${http.directory}/git/${name}

      ${pkgs.stagit}/bin/stagit \
        -l 128 \
        -u https://${domain} \
        ${git.directory}/${name}

      # Make log.html the default page
      cp log.html index.html

      # Copy the static files from the index page
      cp ../favicon.png favicon.png
      cp ../logo.png logo.png
      cp ../style.css style.css

      echo "Stagit page generated for ${name}: <www>/git/${name}."
    '';
in
rec {
  imports = [ ./disk-config.nix ];

  fs = {
    services = {
      dns = {
        enable = true;
        dnssec.enable = true;
        inherit (networking) domain;
        isSecondary = false;
        secondaryIp = (import ../mail/ip.nix).ipv6;
        records = import ./dns.nix domain;
      };
      git = {
        enable = true;
        repositories =
          {
            flake = {
              description = "Personal Nix flake.";
              isPrivate = false;
            };
            pr = {
              description = "Simple package manager for POSIX systems.";
              isPrivate = false;
            };
            site = {
              description = "Personal site.";
              isPrivate = false;
            };
            zion = {
              description = "Operating system.";
              isPrivate = false;
            };
          }
          |> builtins.mapAttrs (
            name:
            { description, isPrivate }:
            {
              inherit isPrivate;
              additionalFiles = {
                inherit description;
                owner = "Francesco Saccone";
                url = "git://${domain}/${name}";
              };
              hooks =
                if isPrivate then
                  { }
                else
                  {
                    postReceive =
                      let
                        inherit (config.fs.services) http git;
                      in
                      pkgs.writeShellScript "post-receive.sh" ''
                        set -e

                        # Define is_force=1 if 'git push -f' was used
                        null_ref="0000000000000000000000000000000000000000"
                        is_force=0
                        while read -r old new red; do
                          test "$old" = $null_ref && continue
                          test "$new" = $null_ref && continue

                          has_revs=$(${pkgs.git}/bin/git rev-list "$old" "^$new" | \
                                     sed 1q)

                          if test -n "$has_revs"; then
                            is_force=1
                            break
                          fi
                        done

                        # If is_force is 1, delete HTML commits
                        if test $is_force = 1; then
                          rm -rf ${http.directory}/${name}/commit
                        fi

                        ${generateStagitRepository name}
                      '';
                  };
            }
          );
        daemon = {
          enable = true;
        };
      };
      http = {
        enable = true;
        inherit (config.fs.services.git) user group;
        redirectWwwToNonWww = {
          enable = true;
          inherit domain;
        };
        errorPages = {
          "404" = "${site}/errors/404.html";
          "5xx" = "${site}/errors/5xx.html";
        };
        preStart = {
          scripts =
            let
              inherit (config.fs.services.http) directory;
            in
            [
              (pkgs.writeShellScript "copy-site.sh" ''
                cp -rf ${site}/root/* ${directory}
              '')
            ]
            ++ (
              config.fs.services.git.repositories
              |> builtins.mapAttrs (
                name:
                { isPrivate, ... }:
                {
                  inherit name isPrivate;
                }
              )
              |> builtins.attrValues
              |> builtins.filter ({ isPrivate, ... }: !isPrivate)
              |> builtins.map ({ name, ... }: generateStagitRepository name)
            );
        };
        acme = {
          enable = true;
          email = "admin@${domain}";
          inherit domain;
          extraDomains = [ "www.${domain}" ];
        };
        tls = {
          enable = true;
          pemFiles =
            let
              inherit (config.fs.services.http.acme) directory;
            in
            [
              "${directory}/${domain}/fullchain.pem"
              "${directory}/${domain}/privkey.pem"
            ];
        };
      };
    };

    security.ssh.listen = {
      enable = true;
      authorizedKeyFiles = rec {
        root = [ ./ssh/francescosaccone.pub ];
        git = root;
      };
    };
  };

  networking = { inherit domain; };
}
