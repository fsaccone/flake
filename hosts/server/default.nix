{
  config,
  pkgs,
  inputs,
  ...
}:
rec {
  imports = [
    ./disk-config.nix
  ];

  modules = {
    agate = {
      enable = true;
      preStart = {
        scripts =
          let
            generateAtom = builtins.concatStringsSep " " [
              "${inputs.site}/scripts/generate-atom.sh"
              "/tmp/site/gemini"
              "\"Francesco Saccone's blog\""
              "gemini://${networking.domain}"
            ];
            generateSitemap = builtins.concatStringsSep " " [
              "${inputs.site}/scripts/generate-sitemap.sh"
              "/tmp/site/gemini"
              "gemini://${networking.domain}"
            ];
            generateGemini = builtins.concatStringsSep " " [
              "${inputs.site}/scripts/generate-gemini.sh"
              "/tmp/site/gemini"
            ];
          in
          [
            generateAtom
            generateSitemap
            generateGemini
          ];
        packages = [
          pkgs.coreutils
          pkgs.findutils
          pkgs.gnused
          pkgs.lowdown
        ];
      };
      symlinks = {
        "index.gmi" = "/tmp/site/gemini/index.gmi";
        "blog" = "/tmp/site/gemini/blog";
        "code" = "/tmp/site/gemini/code";
        "public" = "${inputs.site}/public";
        "robots.txt" = "${inputs.site}/robots.txt";
        "atom.xml" = "/tmp/site/gemini/atom.xml";
        "sitemap.xml" = "/tmp/site/gemini/sitemap.xml";
      };
    };
    bind = {
      enable = true;
      inherit (networking) domain;
      records = import ./dns.nix networking.domain;
    };
    darkhttpd = rec {
      enable = true;
      preStart = {
        scripts =
          let
            generateAtom = builtins.concatStringsSep " " [
              "${inputs.site}/scripts/generate-atom.sh"
              "/tmp/site/html"
              "\"Francesco Saccone's blog\""
              "https://${networking.domain}"
            ];
            generateSitemap = builtins.concatStringsSep " " [
              "${inputs.site}/scripts/generate-sitemap.sh"
              "/tmp/site/html"
              "https://${networking.domain}"
            ];
            generateHtml = builtins.concatStringsSep " " [
              "${inputs.site}/scripts/generate-html.sh"
              "/tmp/site/html"
            ];
          in
          [
            generateAtom
            generateSitemap
            generateHtml
          ];
        packages = [
          pkgs.coreutils
          pkgs.findutils
          pkgs.gnused
          pkgs.lowdown
        ];
      };
      symlinks = {
        "index.html" = "/tmp/site/html/index.html";
        "blog" = "/tmp/site/html/blog";
        "code" = "/tmp/site/html/code";
        "public" = "${inputs.site}/public";
        "favicon.ico" = "${inputs.site}/favicon.ico";
        "robots.txt" = "${inputs.site}/robots.txt";
        "atom.xml" = "/tmp/site/html/atom.xml";
        "sitemap.xml" = "/tmp/site/html/sitemap.xml";
      };
      acme = {
        enable = true;
        email = "admin@${networking.domain}";
        inherit (networking) domain;
        extraDomains = builtins.map (sub: "${sub}.${networking.domain}") [
          "www"
        ];
      };
      tls = {
        enable = true;
        pemFiles =
          let
            inherit (config.modules.darkhttpd.acme) directory;
          in
          [
            "${directory}/${acme.domain}/fullchain.pem"
            "${directory}/${acme.domain}/privkey.pem"
          ];
      };
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
          prometheus = {
            description = "Prometheus.";
          };
          sbase = {
            description = "Francesco Saccone's fork of suckless UNIX tools.";
          };
          site = {
            description = "Francesco Saccone's site content.";
          };
          st = {
            description = "Simple terminal.";
          };
          ubase = {
            description = ''
              Francesco Saccone's fork of suckless Linux base utils.
            '';
          };
        }
        |> builtins.mapAttrs (
          name:
          { description }:
          {
            additionalFiles = {
              inherit description;
              owner = "Francesco Saccone";
              url = "git://${networking.domain}/${name}";
            };
            hooks.postReceive =
              let
                destDir = "/tmp/stagit";
                cacheFile = "${destDir}/.htmlcache";
                reposDir = config.modules.git.directory;
                flags = builtins.concatStringsSep " " [
                  "-c ${cacheFile}"
                  "-u https://${networking.domain}/git/${name}"
                ];

                script = pkgs.writeShellScriptBin "stagit" ''
                  # Define is_force=1 if 'git push -f' was used
                  null="0000000000000000000000000000000000000000"
                  is_force=0
                  while read -r old new ref; do
                    ${pkgs.sbase}/bin/test "$old" = $null && continue
                    ${pkgs.sbase}/bin/test "$new" = $null && continue

                    hasRevs=$(${pkgs.git}/bin/git rev-list "$old" "^$new" | \
                      ${pkgs.sbase}/bin/sed 1q)

                    if ${pkgs.sbase}/bin/test -n "$hasRevs"; then
                      force=1
                      break
                    fi
                  done

                  # If is_force = 1, remove commits and cache file
                  if ${pkgs.sbase}/bin/test $force = "1"; then
                    ${pkgs.sbase}/bin/rm -f ${cacheFile}
                    ${pkgs.sbase}/bin/rm -rf ${reposDir}/${name}/commit
                  fi

                  ${pkgs.sbase}/bin/mkdir -p ${destDir}/${name}
                  cd ${destDir}/${name}
                  ${pkgs.stagit}/bin/stagit ${flags} ${reposDir}/${name}
                  ${pkgs.stagit}/bin/stagit-index ${reposDir}/*/ \
                    > ${destDir}/index.html

                  ${pkgs.sbase}/bin/ln -sf \
                    ${destDir}/${name}/log.html \
                    ${destDir}/${name}/index.html

                  # Symlink favicon.png and logo.png from site
                  ${pkgs.sbase}/bin/ln -sf \
                    ${inputs.site}/public/icon/256.png \
                    ${destDir}/favicon.png

                  ${pkgs.sbase}/bin/ln -sf \
                    ${inputs.site}/public/icon/32.png \
                    ${destDir}/logo.png

                  # Symlink favicon.png and logo.png in repos from index
                  ${pkgs.sbase}/bin/ln -sf \
                    ${destDir}/favicon.png \
                    ${destDir}/${name}/favicon.png

                  ${pkgs.sbase}/bin/ln -sf \
                    ${destDir}/logo.png \
                    ${destDir}/${name}/logo.png
                '';
              in
              "${script}/bin/stagit";
          }
        );
      daemon = {
        enable = true;
      };
    };
    openssh.listen = {
      enable = true;
      port = 22;
      authorizedKeyFiles = rec {
        root = [
          ./ssh/francescosaccone.pub
        ];
        git = root;
      };
    };
  };

  networking.domain = "francescosaccone.com";

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
}
