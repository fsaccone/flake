{
  config,
  pkgs,
  inputs,
  ...
}:
let
  domain = import ./domain.nix;
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
        extraDomains = [ "www.${domain}" ];
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
    openssh.listen = {
      enable = true;
      port = 22;
      authorizedKeyFiles = rec {
        root = [
          ./ssh/francescosaccone.pub
        ];
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
