{
  config,
  ...
}:
let
  mainServer = ../main-server;

  domain = import "${mainServer}/domain.nix";
  gitDomain = "git.${domain}";
in
{
  imports = [
    ./disk-config.nix
  ];

  modules = {
    bind = {
      enable = true;
      inherit domain;
      records = import "${mainServer}/dns.nix" domain;
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
