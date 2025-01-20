{
  lib,
  options,
  config,
  ...
}:
{
  imports = [
    ./monero
    ./networkmanager
    ./openssh
    ./pipewire
    ./searx
    ./sudo
    ./sway
    ./tlp
    ./tor
  ];

  config.modules = {
    monero.enable = lib.mkDefault false;
    networkmanager.enable = lib.mkDefault false;
    openssh = {
      enable = lib.mkDefault false;
      agent.enable = lib.mkDefault false;
      listen.enable = lib.mkDefault false;
    };
    pipewire.enable = lib.mkDefault false;
    searx.enable = lib.mkDefault false;
    sudo.enable = lib.mkDefault false;
    sway.enable = lib.mkDefault false;
    tlp.enable = lib.mkDefault false;
    tor.enable = lib.mkDefault false;
  };
}
