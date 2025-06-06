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
      merecat = {
        enable = true;
        preStart = {
          scripts =
            let
              generateAtom = pkgs.writeShellScript "generate-atom" ''
                ${inputs.site}/scripts/generate-atom.sh \
                  ${config.fs.services.merecat.directory} \
                  "Francesco Saccone's blog" \
                  "https://${domain}"
              '';
              generateSitemap = pkgs.writeShellScript "generate-sitemap" ''
                ${inputs.site}/scripts/generate-sitemap.sh \
                  ${config.fs.services.merecat.directory} \
                  "https://${domain}"
              '';
              generateHtml = pkgs.writeShellScript "generate-html" ''
                ${inputs.site}/scripts/generate-html.sh \
                  ${config.fs.services.merecat.directory}
              '';
              copyStaticContent = pkgs.writeShellScript "copy-static-content" ''
                ${pkgs.sbase}/bin/cp -r \
                  ${inputs.site}/public \
                  ${inputs.site}/favicon.ico \
                  ${inputs.site}/robots.txt \
                  ${config.fs.services.merecat.directory}
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
          email = "francesco@${domain}";
          inherit domain;
          extraDomains = [ "www.${domain}" ];
        };
        tls = {
          enable = true;
          pemFiles =
            let
              inherit (config.fs.services.merecat.acme) directory;
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
