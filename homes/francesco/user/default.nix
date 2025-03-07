{
  lib,
  config,
  pkgs,
  ...
}:
{
  users.users."francesco" = {
    description = "Francesco Saccone";
    hashedPassword =
      let
        hashedPassword = builtins.readFile ./hashedPassword.txt;
      in
      lib.strings.trim hashedPassword;
    isNormalUser = true;
    extraGroups = [
      "audio"
      "networkmanager"
      "realtime"
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
