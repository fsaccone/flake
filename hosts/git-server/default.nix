{
  config,
  pkgs,
  inputs,
  ...
}:
let
  mainServer = ../main-server;

  rootDomain = import "${mainServer}/domain.nix";
  domain = "git.${rootDomain}";

  generateStagitRepository =
    let
      inherit (config.fs.services) static-web-server git;
    in
    name:
    pkgs.writeShellScript "generate-stagit" ''
      set -e

      # Create index.html
      ${pkgs.stagit}/bin/stagit-index \
        ${git.directory}/*/ > ${static-web-server.directory}/index.html

      # Copy favicon.png, logo.png, style.css from site repository
      ${pkgs.sbase}/bin/cp \
        ${inputs.site}/public/icon/256.png \
        ${static-web-server.directory}/favicon.png

      ${pkgs.sbase}/bin/cp \
        ${inputs.site}/public/icon/32.png \
        ${static-web-server.directory}/logo.png

      ${pkgs.sbase}/bin/cp \
        ${inputs.site}/public/stagit.css \
        ${static-web-server.directory}/style.css

      ${pkgs.sbase}/bin/echo \
        "Stagit index file generated: <www>/index.html".

      # Create repository pages
      ${pkgs.sbase}/bin/mkdir -p ${static-web-server.directory}/${name}

      cd ${static-web-server.directory}/${name}

      ${pkgs.stagit}/bin/stagit \
        -l 100 \
        -u https://${domain} \
        ${git.directory}/${name}

      # Make log.html the default page
      ${pkgs.sbase}/bin/cp log.html index.html

      # Copy the static files from the index page
      ${pkgs.sbase}/bin/cp ../style.css style.css
      ${pkgs.sbase}/bin/cp ../favicon.png favicon.png
      ${pkgs.sbase}/bin/cp ../logo.png logo.png

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
                url = "https://${domain}/${name}";
              };
              hooks.postReceive =
                let
                  inherit (config.fs.services) static-web-server git;
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
                    ${pkgs.sbase}/bin/rm -rf ${static-web-server.directory}/${name}/commit
                  fi

                  ${generateStagitRepository name}
                '';
            }
          );
        daemon = {
          enable = true;
        };
      };

      static-web-server = {
        enable = true;
        inherit (config.fs.services.git) user group;
        redirectWwwToNonWww = {
          enable = true;
          inherit domain;
        };
        preStart = {
          scripts =
            let
              copyRepositories =
                let
                  inherit (config.fs.services) git static-web-server;
                in
                pkgs.writeShellScript "copy-repositories" ''
                  ${pkgs.sbase}/bin/cp -fRL \
                    ${git.directory}/* \
                    ${static-web-server.directory}

                  # Enable the dumb HTTP protocol
                  for dir in ${static-web-server.directory}/*/; do
                    ${pkgs.sbase}/bin/mkdir $dir/hooks
                    ${pkgs.sbase}/bin/echo \
                      "exec git update-server-info" > $dir/hooks/post-update
                    ${pkgs.sbase}/bin/chmod a+x $dir/hooks/post-update
                  done
                '';
            in
            [ copyRepositories ]
            ++ builtins.map generateStagitRepository (
              builtins.attrNames config.fs.services.git.repositories
            );
        };
        acme = {
          enable = true;
          email = "francesco@${rootDomain}";
          inherit domain;
          extraDomains = [ "www.${domain}" ];
        };
        tls = {
          enable = true;
          pemFiles =
            let
              inherit (config.fs.services.static-web-server.acme) directory;
            in
            [
              "${directory}/${domain}/fullchain.pem"
              "${directory}/${domain}/privkey.pem"
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

  networking.domain = domain;
}
