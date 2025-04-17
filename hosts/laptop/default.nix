{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
{
  modules = {
    doas = {
      enable = true;
    };
    ly = {
      enable = true;
    };
    monero = {
      enable = true;
      mining = {
        enable = true;
        address = builtins.concatStringsSep "" [
          "47y5LAtYdpZ4GAE7CMx1soEHjUKzpVQFYM5Pv836FcsZd6k3TFcdvHMAHDpwZgnx"
          "4DdG2zkZkSewLgguU23FYJP7HacSVcx"
        ];
      };
    };
    networkmanager = {
      enable = true;
      randomiseMacAddress = true;
    };
    openssh.agent = {
      enable = true;
    };
    sway = {
      enable = true;
    };
    tlp = {
      enable = true;
    };
  };

  services.flatpak.enable = true;

  services.pipewire = {
    enable = true;
    jack.enable = true;
  };

  fonts.packages = [
    pkgs.ibm-plex
  ];

  users.users."francesco" = {
    description = "Francesco Saccone";
    hashedPassword = builtins.concatStringsSep "" [
      "$y$j9T$ZJ7/UHs2qss.7QaCKrAOY/$A6u2M1y7IKyZjj0du"
      "kLW8vQW87hzB/iSklEX6ecqajD"
    ];
    isNormalUser = true;
    extraGroups = [
      "audio"
      "networkmanager"
      "wheel"
    ];
    createHome = true;
    home = "/home/francesco";
    shell = "${pkgs.mksh}/bin/mksh";
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bkp";

    extraSpecialArgs = {
      inherit inputs;
    };

    users.francesco =
      { ... }:
      {
        imports = [
          ./home
          inputs.self.outputs.nixosModules.home-manager
        ];

        home.stateVersion = "25.05";
      };
  };

  security.pam.loginLimits = [
    {
      domain = "@realtime";
      type = "hard";
      item = "rtprio";
      value = 20;
    }
    {
      domain = "@realtime";
      type = "soft";
      item = "rtprio";
      value = 10;
    }
    {
      domain = "@audio";
      type = "-";
      item = "rtprio";
      value = 95;
    }
    {
      domain = "@audio";
      type = "-";
      item = "memlock";
      value = "unlimited";
    }
  ];
}
