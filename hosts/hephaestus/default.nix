{
  config,
  pkgs,
  inputs,
  ...
}:
let
  rootDomain = import ../hades/domain.nix;
  domain = "git.${rootDomain}";

  generateGmnigitRepository =
    let
      inherit (config.fs.services) gemini git;

      indexGmi = builtins.toFile "index.gmi" ''
        # Repositories

        ${
          (
            git.repositories
            |> builtins.mapAttrs (
              name:
              { additionalFiles, ... }:
              ''
                => ${name} [${name}]
                ${additionalFiles.description}
              ''
            )
            |> builtins.attrValues
            |> builtins.concatStringsSep "\n"
          )
        }
      '';
    in
    name:
    pkgs.writeShellScript "generate-gmnigit.sh" ''
      set -e

      # Create index.gmi
      cp ${indexGmi} ${gemini.directory}/index.gmi

      echo "Gmnigit index file generated: <gemini>/index.gmi".

      # Create repository pages
      mkdir -p ${gemini.directory}/${name}

      ${pkgs.gmnigit}/bin/gmnigit \
        -repo ${git.directory}/${name} \
        -dist ${gemini.directory}/${name} \
        -url "git://${domain}/${name}" \
        -perms \
        -refs \
        -name "${name}" \
        -max-commits 128

      echo "Gmnigit page generated for ${name}: <gemini>/${name}."
    '';

  generateStagitRepository =
    let
      inherit (config.fs.services) web git;
    in
    name:
    pkgs.writeShellScript "generate-stagit.sh" ''
      set -e

      # Create index.html
      cd ${web.directory}

      ${pkgs.stagit}/bin/stagit-index ${git.directory}/*/ > index.html

      # Copy favicon.png, logo.png, style.css from site repository
      cp ${inputs.site}/public/icon/32.png favicon.png
      cp favicon.png logo.png
      cp ${inputs.site}/public/stagit.css style.css

      # This is needed because when the script is run one time after
      # the other the copying of the static files brings a "Permission denied"
      # error, since they only have read permission at creation.
      chmod -R u+w .

      echo "Stagit index file generated: <www>/index.html".

      # Create repository pages
      mkdir -p ${web.directory}/${name}
      cd ${web.directory}/${name}

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

      echo "Stagit page generated for ${name}: <www>/${name}."
    '';
in
{
  imports = [ ./disk-config.nix ];

  fs = {
    services = {

      dns = {
        enable = true;
        domain = rootDomain;
        isSecondary = true;
        primaryIp = (import ../hades/ip.nix).ipv6;
        records = import ../hades/dns.nix rootDomain;
      };

      gemini = {
        enable = true;
        inherit (config.fs.services.git) user group;
        tls =
          let
            inherit (config.fs.services.web.acme) directory;
          in
          {
            certificate = "${directory}/${domain}/fullchain.pem";
            key = "${directory}/${domain}/privkey.pem";
          };
        preStart = {
          scripts =
            let
              inherit (config.fs.services.gemini) directory;
            in
            [
              (pkgs.writeShellScript "create-robots-txt.sh" ''
                echo "User-agent: *" > ${directory}/robots.txt
                echo "Disallow: /" >> ${directory}/robots.txt
              '')
            ]
            ++ builtins.map generateGmnigitRepository (
              builtins.attrNames config.fs.services.git.repositories
            );
          packages = [ pkgs.git ];
        };
      };

      git = {
        enable = true;
        repositories =
          {
            flake = {
              description = "Francesco Saccone's Nix flake.";
            };
            pass = {
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
                url = "git://${domain}/${name}";
              };
              hooks.postReceive =
                let
                  inherit (config.fs.services) gemini web git;
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
                    rm -rf ${web.directory}/${name}/commit
                    rm -rf ${gemini.directory}/${name}/commits
                  fi

                  ${generateStagitRepository name}
                  ${generateGmnigitRepository name}
                '';
            }
          );
        daemon = {
          enable = true;
        };
      };

      web = {
        enable = true;
        inherit (config.fs.services.git) user group;
        redirectWwwToNonWww = {
          enable = true;
          inherit domain;
        };
        preStart = {
          scripts =
            let
              inherit (config.fs.services.web) directory;
            in
            [
              (pkgs.writeShellScript "create-robots-txt.sh" ''
                echo "User-agent: *" > ${directory}/robots.txt
                echo "Disallow: /" >> ${directory}/robots.txt
              '')
            ]
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
              inherit (config.fs.services.web.acme) directory;
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
      authorizedKeyFiles = rec {
        root = [ ../hades/ssh/francescosaccone.pub ];
        git = root;
      };
    };
  };

  networking.domain = domain;
}
