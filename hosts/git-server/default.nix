{
  config,
  ...
}:
{
  imports = [
    ./disk-config.nix
  ];

  modules = {
    bind = rec {
      enable = true;
      domain = "francescosaccone.com";
      records = import ../server/dns.nix domain;
    };
    openssh.listen = {
      enable = true;
      port = 22;
      authorizedKeyFiles = rec {
        root = [
          ../server/ssh/francescosaccone.pub
        ];
      };
    };
  };

  networking.domain = "git.francescosaccone.com";

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
}
