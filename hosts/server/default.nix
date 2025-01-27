{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./disk-config.nix
  ];

  modules = {
    networking = {
      openssh = {
        enable = true;
        listen = {
          enable = true;
          port = 22;
          authorizedKeyFiles = {
            "admin" = [
              ./sshKeys/francescoSaccone
            ];
          };
        };
      };
    };

    system = {
      sudo.enable = true;
    };
  };

  networking.hostName = "francescosaccone-server";

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  users.users.admin = {
    description = "Admin";
    hashedPassword = "$y$j9T$r6EXIhMdkO393N/WJwa6s.$05A9CJwt6PirGcPWSkDG53vTzrglRcJ8lHBO1IoO0PA";
    isNormalUser = true;
    extraGroups = [
      "wheel"
    ];
    createHome = true;
    home = "/home/admin";
  };
}
