{
  lib,
  options,
  config,
  ...
}:
{
  imports = [
    ./aerc
    ./firefox
    ./git
    ./gpg
    ./mediaViewers
    ./neovim
    ./sway
  ];

  config.modules = {
    aerc.enable = lib.mkDefault false;
    firefox.enable = lib.mkDefault false;
    git.enable = lib.mkDefault false;
    gpg.enable = lib.mkDefault false;
    mediaViewers.enable = lib.mkDefault false;
    neovim.enable = lib.mkDefault false;
    sway.enable = lib.mkDefault false;
  };
}
