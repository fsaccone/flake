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
      web = {
        enable = true;
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
                  ${inputs.site}/scripts/generate-404.sh $out
                '';
              };
              "5xx" = pkgs.stdenv.mkDerivation {
                name = "5xx-page";
                buildInputs = [ pkgs.lowdown ];
                buildCommand = ''
                  ${inputs.site}/scripts/generate-5xx.sh $out
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

              generateAtom = pkgs.writeShellScript "generate-atom" ''
                ${inputs.site}/scripts/generate-atom.sh \
                  ${directory} \
                  "Francesco Saccone's blog" \
                  "https://${domain}"
              '';
              generateSitemap = pkgs.writeShellScript "generate-sitemap" ''
                ${inputs.site}/scripts/generate-sitemap.sh \
                  ${directory} \
                  "https://${domain}"
              '';
              generateHtml = pkgs.writeShellScript "generate-html" ''
                ${inputs.site}/scripts/generate-html.sh ${directory}
              '';
              createRobotsTxt = pkgs.writeShellScript "create-robots-txt" ''
                echo "User-agent: *" > ${directory}/robots.txt
                echo "Disallow:" >> ${directory}/robots.txt
              '';
              copyStaticContent = pkgs.writeShellScript "copy-static-content" ''
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
      port = 22;
      authorizedKeyFiles = rec {
        root = [ ./ssh/francescosaccone.pub ];
      };
    };
  };

  networking = { inherit domain; };
}
