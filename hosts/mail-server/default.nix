{
  config,
  pkgs,
  inputs,
  ...
}:
let
  mainServer = ../main-server;

  rootDomain = import "${mainServer}/domain.nix";
  domain = "mail.${rootDomain}";
in
{
  imports = [ ./disk-config.nix ];

  fs = {
    services = {
      email = {
        enable = true;
        hostDomain = domain;
        domain = rootDomain;
        tls =
          let
            inherit (config.fs.services.web.acme) directory;
          in
          {
            certificate = "${directory}/${domain}/fullchain.pem";
            key = "${directory}/${domain}/privkey.pem";
          };
        users = {
          francesco = {
            hashedPassword = builtins.concatStringsSep "" [
              "$y$j9T$bijM0Sx8zmb63dV6WnzJP1$L7AflYFAk"
              "K.joHgsnE8OqgzOTiry1UpbX5xcbj5V7.."
            ];
          };
        };
      };
      web = {
        enable = true;
        acme = {
          enable = true;
          email = "francesco@${rootDomain}";
          inherit domain;
        };
      };
    };

    security.openssh.listen = {
      enable = true;
      authorizedKeyFiles = rec {
        root = [ "${mainServer}/ssh/francescosaccone.pub" ];
      };
    };
  };

  networking.domain = domain;
}
