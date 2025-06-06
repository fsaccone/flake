{
  config,
  pkgs,
  inputs,
  ...
}:
let
  mainServer = ../main-server;

  rootDomain = import "${mainServer}/domain.nix";
  gitDomain = "git.${rootDomain}";

  generateStagitRepository =
    let
      inherit (config.fs.services) merecat git;
    in
    name:
    pkgs.writeShellScript "generate-stagit" ''
      set -e

      # Create index.html
      ${pkgs.stagit}/bin/stagit-index \
        ${git.directory}/*/ > ${merecat.directory}/index.html

      # Copy favicon.png, logo.png, style.css from site repository
      ${pkgs.sbase}/bin/cp \
        ${inputs.site}/public/icon/256.png \
        ${merecat.directory}/favicon.png

      ${pkgs.sbase}/bin/cp \
        ${inputs.site}/public/icon/32.png \
        ${merecat.directory}/logo.png

      ${pkgs.sbase}/bin/cp \
        ${inputs.site}/public/stagit.css \
        ${merecat.directory}/style.css

      ${pkgs.sbase}/bin/echo \
        "Stagit index file generated: <www>/index.html".

      # Create repository pages
      ${pkgs.sbase}/bin/mkdir -p ${merecat.directory}/${name}

      cd ${merecat.directory}/${name}

      ${pkgs.stagit}/bin/stagit \
        -l 100 \
        -u https://${gitDomain} \
        ${git.directory}/${name}

      # Make log.html the default page
      ${pkgs.sbase}/bin/ln -sf log.html index.html

      # Symlink the static files from the index page
      ${pkgs.sbase}/bin/ln -sf ../style.css style.css
      ${pkgs.sbase}/bin/ln -sf ../favicon favicon
      ${pkgs.sbase}/bin/ln -sf ../logo.png logo.png

      ${pkgs.sbase}/bin/echo \
        "Stagit page generated for ${name}: <www>/${name}."
    '';
in
{
  imports = [ ./disk-config.nix ];

  fs = {
    services = {

      dns = {
        enable = true;
        domain = rootDomain;
        records = import "${mainServer}/dns.nix" rootDomain;
      };

      git = {
        enable = true;
        repositories =
          {
            flake = {
              description = "Francesco Saccone's Nix flake.";
            };
            password-store = {
              description = "Francesco Saccone's password store.";
            };
            site = {
              description = "Francesco Saccone's site content.";
            };
          }
          |> builtins.mapAttrs (
            name:
            { description }:
            {
              additionalFiles = {
                inherit description;
                owner = "Francesco Saccone";
                url = "https://${gitDomain}/${name}";
              };
              hooks.postReceive =
                let
                  inherit (config.fs.services) merecat git;
                in
                pkgs.writeShellScript "post-receive" ''
                  set -e

                  # Define is_force=1 if 'git push -f' was used
                  null_ref="0000000000000000000000000000000000000000"
                  is_force=0
                  while read -r old new red; do
                    ${pkgs.sbase}/bin/test "$old" = $null_ref && continue
                    ${pkgs.sbase}/bin/test "$new" = $null_ref && continue

                    has_revs=$(${pkgs.git}/bin/git rev-list "$old" "^$new" | \
                               ${pkgs.sbase}/bin/sed 1q)

                    if ${pkgs.sbase}/bin/test -n "$has_revs"; then
                      is_force=1
                      break
                    fi
                  done

                  # If is_force is 1, delete HTML commits
                  if ${pkgs.sbase}/bin/test $is_force = 1; then
                    ${pkgs.sbase}/bin/rm -rf ${merecat.directory}/${name}/commit
                  fi

                  ${generateStagitRepository name}
                '';
            }
          );
        daemon = {
          enable = true;
        };
      };

      merecat = {
        enable = true;
        inherit (config.fs.services.git) user group;
        preStart = {
          scripts =
            let
              copyRepositories = pkgs.writeShellScript "copy-repositories" ''
                ${pkgs.sbase}/bin/cp -fRL \
                  ${config.fs.services.git.directory}/* \
                  ${config.fs.services.merecat.directory}
              '';
            in
            [ copyRepositories ];
        };
        acme = {
          enable = true;
          email = "francesco@${rootDomain}";
          domain = gitDomain;
          extraDomains = [ "www.${gitDomain}" ];
        };
        tls = {
          enable = true;
          pemFiles =
            let
              inherit (config.fs.services.merecat.acme) directory;
            in
            [
              "${directory}/${gitDomain}/fullchain.pem"
              "${directory}/${gitDomain}/privkey.pem"
            ];
        };
      };
    };

    security.openssh.listen = {
      enable = true;
      port = 22;
      authorizedKeyFiles = rec {
        root = [ "${mainServer}/ssh/francescosaccone.pub" ];
        git = root;
      };
    };
  };

  networking.domain = gitDomain;
}
