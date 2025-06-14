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
    security.openssh.listen = {
      enable = true;
      port = 22;
      authorizedKeyFiles = rec {
        root = [ "${mainServer}/ssh/francescosaccone.pub" ];
      };
    };
  };

  networking.domain = domain;
}
