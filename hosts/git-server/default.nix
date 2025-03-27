{
  config,
  ...
}:
{
  imports = [
    ./disk-config.nix
  ];

  modules = {
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
