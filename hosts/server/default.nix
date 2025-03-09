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
        script = "${inputs.site}/scripts/generate-gemini.sh /tmp/site/gemini";
        packages = [
          pkgs.coreutils
          pkgs.findutils
          pkgs.lowdown
        ];
      };
      symlinks = {
        "index.gmi" = "/tmp/site/gemini/index.gmi";
        "blog" = "/tmp/site/gemini/blog";
        "public" = "${inputs.site}/public";
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
        script = "${inputs.site}/scripts/generate-html.sh /tmp/site/html";
        packages = [
          pkgs.coreutils
          pkgs.findutils
          pkgs.lowdown
        ];
      };
      symlinks = {
        "index.html" = "/tmp/site/html/index.html";
        "blog" = "/tmp/site/html/blog";
        "public" = "${inputs.site}/public";
        "favicon.ico" = "${inputs.site}/favicon.ico";
        "robots.txt" = "${inputs.site}/robots.txt";
      };
      customHeaderScripts =
        let
          getOnionAddress = pkgs.writeShellScriptBin "get-onion-address" ''
            HOSTNAME=$(${pkgs.coreutils}/bin/cat \
            ${config.modules.tor.servicesDirectory}/website/hostname)

            ${pkgs.coreutils}/bin/echo "http://$HOSTNAME"
          '';
        in
        {
          "Onion-Location" = "${getOnionAddress}/bin/get-onion-address";
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
          site = {
            description = "Francesco Saccone's site content.";
          };
        }
        |> builtins.mapAttrs (
          name:
          { description }:
          {
            inherit description;
            owner = "Francesco Saccone";
            baseUrl = networking.domain;
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
    tor = {
      enable = true;
      services = {
        website = {
          ports = [
            80
            443
          ];
        };
      };
    };
  };

  networking.domain = "francescosaccone.com";

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
}
