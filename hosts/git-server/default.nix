{
  config,
  pkgs,
  inputs,
  ...
}:
let
  mainServer = ../main-server;

  rootDomain = import "${mainServer}/domain.nix";
  gitDomain = "git.${rootDomain}";

  scripts = import ./scripts.nix { inherit config pkgs inputs; };
in
{
  imports = [
    ./disk-config.nix
  ];

  modules = {
    bind = {
      enable = true;
      domain = rootDomain;
      records = import "${mainServer}/dns.nix" rootDomain;
    };
    darkhttpd = {
      enable = true;
      acme = {
        enable = true;
        email = "admin@${rootDomain}";
        domain = gitDomain;
      };
      tls = {
        enable = true;
        pemFiles =
          let
            inherit (config.modules.darkhttpd.acme) directory;
          in
          [
            "${directory}/${gitDomain}/fullchain.pem"
            "${directory}/${gitDomain}/privkey.pem"
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
              url = "git://${gitDomain}/${name}";
            };
            hooks.postReceive = scripts.stagitPostReceive {
              inherit name;
              httpBaseUrl = "https://${gitDomain}";
            };
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
          "${mainServer}/ssh/francescosaccone.pub"
        ];
      };
    };
  };

  networking.domain = gitDomain;

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
}
