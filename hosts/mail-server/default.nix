{
  config,
  pkgs,
  inputs,
  ...
}:
let
  rootDomain = import ../main-server/domain.nix;
  domain = "mail.${rootDomain}";
in
{
  imports = [ ./disk-config.nix ];

  fs = {
    services = {
      email = {
        enable = true;
        host = {
          inherit domain;
          inherit (import ./ip.nix) ipv4 ipv6;
        };
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
            aliases = [
              "abuse"
              "admin"
              "postmaster"
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
        root = [ ../main-server/ssh/francescosaccone.pub ];
      };
    };
  };

  networking.domain = domain;
}
