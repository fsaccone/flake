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
    bind = {
      enable = true;
      inherit (networking) domain;
      records = import ./dns.nix networking.domain;
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
          website = {
            description = "Francesco Saccone's website content.";
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
      stagit = {
        enable = true;
        baseUrl = "https://${networking.domain}/git";
        iconPng = "${inputs.website}/public/icon/32.png";
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
    pandoc = {
      enable = true;
      input = inputs.website;
      components = {
        head = "${inputs.website}/components/head.html";
        header = "${inputs.website}/components/header.html";
        footer = "${inputs.website}/components/footer.html";
      };
    };
    staticWebServer = rec {
      enable = true;
      symlinks = {
        "favicon.ico" = "${inputs.website}/favicon.ico";
        "robots.txt" = "${inputs.website}/robots.txt";

        "index.html" = "${config.modules.pandoc.output}/index.html";

        "notes" = "${config.modules.pandoc.output}/notes";

        "public" = "${inputs.website}/public";

        "git" = config.modules.git.stagit.output;
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
            inherit (config.modules.staticWebServer.acme) directory;
          in
          [
            "${directory}/${acme.domain}/fullchain.pem"
            "${directory}/${acme.domain}/privkey.pem"
          ];
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
