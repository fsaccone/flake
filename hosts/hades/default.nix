{
  config,
  pkgs,
  inputs,
  ...
}:
let
  domain = import ./domain.nix;

  generateStagitRepository =
    let
      inherit (config.fs.services) web git;
    in
    name:
    pkgs.writeShellScript "generate-stagit.sh" ''
      set -e

      # Create index.html
      mkdir -p ${web.directory}/git
      cd ${web.directory}/git

      ${pkgs.stagit}/bin/stagit-index ${git.directory}/*/ > index.html

      # Copy favicon.png, logo.png, style.css from site repository
      cp ${inputs.site}/public/icon/32.png favicon.png
      cp favicon.png logo.png
      cp ${inputs.site}/public/stagit.css style.css

      # This is needed because when the script is run one time after
      # the other the copying of the static files brings a "Permission denied"
      # error, since they only have read permission at creation.
      chmod -R u+w .

      echo "Stagit index file generated: <www>/git/index.html".

      # Create repository pages
      mkdir -p ${web.directory}/git/${name}
      cd ${web.directory}/git/${name}

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
        secondaryIp = (import ../hermes/ip.nix).ipv6;
        records = import ./dns.nix domain;
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
                  inherit (config.fs.services) web git;
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
                  fi

                  ${generateStagitRepository name}
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
        errorPages =
          let
            pages = {
              "404" = pkgs.stdenv.mkDerivation {
                name = "404-page";
                buildInputs = [ pkgs.lowdown ];
                buildCommand = ''
                  ${inputs.site}/scripts/generate-404-html.sh $out
                '';
              };
              "5xx" = pkgs.stdenv.mkDerivation {
                name = "5xx-page";
                buildInputs = [ pkgs.lowdown ];
                buildCommand = ''
                  ${inputs.site}/scripts/generate-5xx-html.sh $out
                '';
              };
            };
          in
          {
            "404" = pages."404";
            "5xx" = pages."5xx";
          };
        preStart = {
          scripts =
            let
              inherit (config.fs.services.web) directory;

              generateAtom = pkgs.writeShellScript "generate-atom.sh" ''
                ${inputs.site}/scripts/generate-atom.sh \
                  ${directory} \
                  "Francesco Saccone's blog" \
                  "https://${domain}"
              '';
              generateSitemap = pkgs.writeShellScript "generate-sitemap.sh" ''
                ${inputs.site}/scripts/generate-sitemap.sh \
                  ${directory} \
                  "https://${domain}"
              '';
              generateHtml = pkgs.writeShellScript "generate-html.sh" ''
                ${inputs.site}/scripts/generate-html.sh ${directory}
              '';
              createRobotsTxt = pkgs.writeShellScript "create-robots-txt.sh" ''
                echo "User-agent: *" > ${directory}/robots.txt
                echo "Disallow:" >> ${directory}/robots.txt
              '';
              copyStaticContent = pkgs.writeShellScript "copy-static-content.sh" ''
                mkdir -p ${directory}/public

                cp -fR ${inputs.site}/public/* ${directory}/public

                cp ${inputs.site}/favicon.ico ${directory}
              '';
            in
            [
              generateAtom
              generateSitemap
              generateHtml
              createRobotsTxt
              copyStaticContent
            ]
            ++ builtins.map generateStagitRepository (
              builtins.attrNames config.fs.services.git.repositories
            );
          packages = [
            pkgs.coreutils
            pkgs.findutils
            pkgs.gnused
            pkgs.lowdown
          ];
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
              inherit (config.fs.services.web.acme) directory;
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
