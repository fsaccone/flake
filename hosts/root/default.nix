{
  config,
  pkgs,
  inputs,
  ...
}:
let
  domain = import ./domain.nix;

  site = pkgs.stdenv.mkDerivation {
    name = "site";
    src = inputs.site;

    buildInputs = [
      pkgs.imagemagick
      pkgs.inkscape
      pkgs.lowdown
    ];

    postInstall = ''
      mkdir -p $out/errors
      cp -f 404.html 5xx.html $out/errors
    '';

    makeFlags = [ "HOST=${domain}" ];

    installFlags = [ "PREFIX=$(out)/root" ];
  };
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
        secondaryIp = (import ../mail/ip.nix).ipv6;
        records = import ./dns.nix domain;
      };
      git = {
        enable = true;
        repositories = {
          flake = {
            isPrivate = false;
          };
          pr = {
            isPrivate = false;
          };
          site = {
            isPrivate = false;
          };
          zion = {
            isPrivate = false;
          };
        };
        daemon = {
          enable = true;
        };
      };
      http = {
        enable = true;
        inherit (config.fs.services.git) user group;
        redirectWwwToNonWww = {
          enable = true;
          inherit domain;
        };
        errorPages = {
          "404" = "${site}/errors/404.html";
          "5xx" = "${site}/errors/5xx.html";
        };
        preStart = {
          scripts = [
            (pkgs.writeShellScript "copy-site.sh" ''
              cp -rf ${site}/root/* ${config.fs.services.http.directory}
            '')
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
              inherit (config.fs.services.http.acme) directory;
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
