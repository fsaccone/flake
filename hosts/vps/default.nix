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
    sudo.enable = true;
  };

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  services.openssh.enable = true;

  users.users.admin = {
    description = "Admin";
    hashedPassword = "$y$j9T$r6EXIhMdkO393N/WJwa6s.$05A9CJwt6PirGcPWSkDG53vTzrglRcJ8lHBO1IoO0PA";
    isNormalUser = true;
    extraGroups = [
      "wheel"
    ];
    createHome = true;
    home = "/home/admin";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK31ZgIE+tjzEVMfAhsImznrp1V3gGM2BJWtAaV6qLV6 Francesco Saccone"
    ];
  };
}
