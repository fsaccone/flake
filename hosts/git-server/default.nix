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

  stagit = {
    destDir = config.services.quark.directory;
    reposDir = config.services.git.directory;
  };
in
{
  imports = [
    ./disk-config.nix
  ];

  services = {
    dns = {
      enable = true;
      domain = rootDomain;
      records = import "${mainServer}/dns.nix" rootDomain;
    };
    quark = {
      enable = true;
      user = "git";
      preStart = {
        scripts =
          let
            stagitCreate = scripts.stagitCreate {
              inherit (stagit) destDir reposDir;
              httpBaseUrl = "https://${gitDomain}";
            };

            stagitCreateAndChown =
              let
                script = pkgs.writeShellScriptBin "stagit-create-and-chown" ''
                  ${stagitCreate}
                  ${pkgs.sbase}/bin/chown -R git:git ${stagit.destDir}
                  ${pkgs.sbase}/bin/chmod -R u+rw ${stagit.destDir}
                '';
              in
              "${script}/bin/stagit-create-and-chown";

            copyRepositories = pkgs.writeShellScript "copy-repositories" ''
              ${pkgs.sbase}/bin/cp -R \
                ${config.services.git.directory}/* \
                ${config.services.quark.directory}
            '';
          in
          [
            stagitCreateAndChown
            copyRepositories
          ];
      };
      acme = {
        enable = true;
        email = "admin@${rootDomain}";
        domain = gitDomain;
      };
      tls = {
        enable = true;
        pemFiles =
          let
            inherit (config.services.quark.acme) directory;
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
          hermes = {
            description = "HTTP GET/HEAD-only web server for static content.";
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
            additionalFiles = {
              inherit description;
              owner = "Francesco Saccone";
              url = "https://${gitDomain}/${name}";
            };
            hooks.postReceive =
              builtins.concatStringsSep "\n" [
                (scripts.stagitPostReceive {
                  inherit (stagit) destDir reposDir;
                  inherit name;
                  httpBaseUrl = "https://${gitDomain}";
                })
                "git update-server-info" # Dumb HTTP protocol
              ]
              |> pkgs.writeShellScript "post-receive";
          }
        );
      daemon = {
        enable = true;
      };
    };
  };

  security.openssh.listen = {
    enable = true;
    port = 22;
    authorizedKeyFiles = rec {
      root = [
        "${mainServer}/ssh/francescosaccone.pub"
      ];
      git = root;
    };
  };

  networking.domain = gitDomain;
}
