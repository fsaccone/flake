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
  imports = [ ./disk-config.nix ];

  fs = {
    services = {
      dns = {
        enable = true;
        inherit (networking) domain;
        records = import ./dns.nix domain;
      };
      quark = {
        enable = true;
        preStart = {
          scripts =
            let
              generateAtom = builtins.concatStringsSep " " [
                "${inputs.site}/scripts/generate-atom.sh"
                config.fs.services.quark.directory
                "\"Francesco Saccone's blog\""
                "https://${domain}"
              ];
              generateSitemap = builtins.concatStringsSep " " [
                "${inputs.site}/scripts/generate-sitemap.sh"
                config.fs.services.quark.directory
                "https://${domain}"
              ];
              generateHtml = builtins.concatStringsSep " " [
                "${inputs.site}/scripts/generate-html.sh"
                config.fs.services.quark.directory
              ];
              copyStaticContent = pkgs.writeShellScript "copy-static-content" ''
                ${pkgs.sbase}/bin/cp -r \
                  ${inputs.site}/public \
                  ${inputs.site}/favicon.ico \
                  ${inputs.site}/robots.txt \
                  ${config.fs.services.quark.directory}
              '';
            in
            [
              generateAtom
              generateSitemap
              generateHtml
              copyStaticContent
            ];
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
              inherit (config.fs.services.quark.acme) directory;
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
        root = [ ./ssh/francescosaccone.pub ];
      };
    };
  };

  networking = { inherit domain; };
}
