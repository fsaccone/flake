{
  config,
  pkgs,
  inputs,
  ...
}:
let
  mainServer = ../main-server;

  rootDomain = import "${mainServer}/domain.nix";
  domain = "mx.${rootDomain}";
in
{
  imports = [ ./disk-config.nix ];

  fs = {
    services = {
      smtp = {
        enable = true;
        domain = rootDomain;
        tls =
          let
            inherit (config.fs.services.web.acme) directory;
          in
          {
            certificate = "${directory}/${domain}/fullchain.pem";
            key = "${directory}/${domain}/privkey.pem";
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
