{
  lib,
  options,
  config,
  ...
}:
{
  imports = [
    ./aerc
    ./git
    ./gpg
    ./librewolf
    ./mediaViewers
    ./neovim
    ./sway
    ./syncthing
  ];

  config.modules = {
    aerc.enable = lib.mkDefault false;
    git.enable = lib.mkDefault false;
    gpg.enable = lib.mkDefault false;
    librewolf.enable = lib.mkDefault false;
    mediaViewers.enable = lib.mkDefault false;
    neovim.enable = lib.mkDefault false;
    sway.enable = lib.mkDefault false;
    syncthing.enable = lib.mkDefault false;
  };
}
