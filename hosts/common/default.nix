{
  lib,
  config,
  pkgs,
  ...
}:
{
  system.stateVersion = "23.11";

  services.fwupd.enable = true;
  security.protectKernelImage = true;
  boot.tmp.cleanOnBoot = true;

  users = {
    mutableUsers = false;
    defaultUserShell = "${pkgs.dash}/bin/dash";
    users.root = {
      hashedPassword = "!";
    };
  };

  networking.firewall = {
    enable = true;
    package = pkgs.iptables;
  };

  environment.defaultPackages = lib.mkForce [ ];

  i18n.defaultLocale = "en_GB.UTF-8";
  time.timeZone = "Europe/Rome";

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
}
