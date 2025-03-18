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
      "$y$j9T$OeFz3YZ.sA0W62wz7QEyr.$p8n5VCft9O6sdxSedIh4SQ7"
      "JiXWgFI0/E5knPbX9y/3"
    ];
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    createHome = true;
    home = "/home/francesco";
    shell = "${pkgs.bashInteractive}/bin/bash";
  };

  fonts.packages = with pkgs; [
    ibm-plex
  ];
}
