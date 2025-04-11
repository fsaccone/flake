{
  lib,
  config,
  pkgs,
  ...
}:
{
  modules = {
    doas = {
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
    tlp = {
      enable = true;
    };
    wayland = {
      enable = true;
    };
  };

  services.flatpak.enable = true;
}
