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
        script = "${inputs.website}/generate-gemini.sh /tmp/website/gemini";
        packages = [
          pkgs.coreutils
          pkgs.findutils
          pkgs.lowdown
        ];
      };
      symlinks = {
        "index.gmi" = "/tmp/website/gemini/index.gmi";
        "notes" = "/tmp/website/gemini/notes";
      };
    };
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
    staticWebServer = rec {
      enable = true;
      preStart = {
        script = "${inputs.website}/generate-html.sh /tmp/website/html";
        packages = [
          pkgs.coreutils
          pkgs.findutils
          pkgs.lowdown
        ];
      };
      symlinks = {
        "favicon.ico" = "${inputs.website}/favicon.ico";
        "robots.txt" = "${inputs.website}/robots.txt";

        "index.html" = "/tmp/website/html/index.html";
        "notes" = "/tmp/website/html/notes";

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
