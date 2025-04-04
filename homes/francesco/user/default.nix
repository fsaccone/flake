{
  lib,
  config,
  pkgs,
  ...
}:
{
  users.users."francesco" = {
    description = "Francesco Saccone";
    hashedPassword = builtins.concatStringsSep "" [
      "$y$j9T$ZJ7/UHs2qss.7QaCKrAOY/$A6u2M1y7IKyZjj0du"
      "kLW8vQW87hzB/iSklEX6ecqajD"
    ];
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    createHome = true;
    home = "/home/francesco";
    shell = "${pkgs.mksh}/bin/mksh";
  };

  fonts.packages = with pkgs; [
    ibm-plex
  ];
}
