{
  config,
  ...
}:
let
  domain = import ../server/domain.nix;
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

  networking.domain = gitDomain;

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
}
