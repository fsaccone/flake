{
  config,
  pkgs,
  inputs,
  ...
}:
let
  domain = import ./domain.nix;
  scripts = import ./scripts.nix { inherit config pkgs inputs; };
in
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
              "/var/tmp/site/gemini"
              "\"Francesco Saccone's blog\""
              "gemini://${domain}"
            ];
            generateSitemap = builtins.concatStringsSep " " [
              "${inputs.site}/scripts/generate-sitemap.sh"
              "/var/tmp/site/gemini"
              "gemini://${domain}"
            ];
            generateGemini = builtins.concatStringsSep " " [
              "${inputs.site}/scripts/generate-gemini.sh"
              "/var/tmp/site/gemini"
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
        "index.gmi" = "/var/tmp/site/gemini/index.gmi";
        "blog" = "/var/tmp/site/gemini/blog";
        "code" = "/var/tmp/site/gemini/code";
        "public" = "${inputs.site}/public";
        "robots.txt" = "${inputs.site}/robots.txt";
        "atom.xml" = "/var/tmp/site/gemini/atom.xml";
        "sitemap.xml" = "/var/tmp/site/gemini/sitemap.xml";
      };
    };
    bind = {
      enable = true;
      inherit (networking) domain;
      records = import ./dns.nix domain;
    };
    darkhttpd = {
      enable = true;
      preStart = {
        scripts =
          let
            generateAtom = builtins.concatStringsSep " " [
              "${inputs.site}/scripts/generate-atom.sh"
              "/var/tmp/site/html"
              "\"Francesco Saccone's blog\""
              "https://${domain}"
            ];
            generateSitemap = builtins.concatStringsSep " " [
              "${inputs.site}/scripts/generate-sitemap.sh"
              "/var/tmp/site/html"
              "https://${domain}"
            ];
            generateHtml = builtins.concatStringsSep " " [
              "${inputs.site}/scripts/generate-html.sh"
              "/var/tmp/site/html"
            ];
          in
          [
            generateAtom
            generateSitemap
            generateHtml
            scripts.stagitCreate
          ];
        packages = [
          pkgs.coreutils
          pkgs.findutils
          pkgs.gnused
          pkgs.lowdown
        ];
      };
      symlinks = {
        "index.html" = "/var/tmp/site/html/index.html";
        "blog" = "/var/tmp/site/html/blog";
        "code" = "/var/tmp/site/html/code";
        "git" = "/var/tmp/stagit";
        "public" = "${inputs.site}/public";
        "favicon.ico" = "${inputs.site}/favicon.ico";
        "robots.txt" = "${inputs.site}/robots.txt";
        "atom.xml" = "/var/tmp/site/html/atom.xml";
        "sitemap.xml" = "/var/tmp/site/html/sitemap.xml";
      };
      acme = {
        enable = true;
        email = "admin@${domain}";
        inherit domain;
        extraDomains = builtins.map (sub: "${sub}.${domain}") [
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
            "${directory}/${domain}/fullchain.pem"
            "${directory}/${domain}/privkey.pem"
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
          sbase = {
            description = "Francesco Saccone's fork of suckless UNIX tools.";
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
            hooks.postReceive = scripts.stagitPostReceive { inherit name; };
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

  networking = {
    inherit domain;
  };

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
}
