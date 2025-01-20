{
  lib,
  options,
  config,
  ...
}:
{
  imports = [
    ./crypto/monero
    ./desktop/wayland
    ./multimedia/pipewire
    ./networking/networkmanager
    ./networking/openssh
    ./networking/searx
    ./networking/tor
    ./system/sudo
    ./system/tlp
  ];

  config.modules = {
    crypto = {
      monero.enable = lib.mkDefault false;
    };

    desktop = {
      wayland.enable = lib.mkDefault false;
    };

    multimedia = {
      pipewire.enable = lib.mkDefault false;
    };

    networking = {
      networkmanager.enable = lib.mkDefault false;
      openssh = {
        enable = lib.mkDefault false;
        agent.enable = lib.mkDefault false;
        listen.enable = lib.mkDefault false;
      };
      searx.enable = lib.mkDefault false;
      tor.enable = lib.mkDefault false;
    };

    system = {
      sudo.enable = lib.mkDefault false;
      tlp.enable = lib.mkDefault false;
    };
  };
}
