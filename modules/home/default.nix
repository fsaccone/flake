{
  lib,
  options,
  config,
  ...
}:
{
  imports = [
    ./firefox
    ./git
    ./gpg
    ./mediaViewers
    ./moneroWallet
    ./neomutt
    ./neovim
    ./sway
    ./syncthing
  ];

  config.modules = {
    firefox.enable = lib.mkDefault false;
    git.enable = lib.mkDefault false;
    gpg.enable = lib.mkDefault false;
    mediaViewers.enable = lib.mkDefault false;
    moneroWallet.enable = lib.mkDefault false;
    neomutt.enable = lib.mkDefault false;
    neovim.enable = lib.mkDefault false;
    sway.enable = lib.mkDefault false;
    syncthing.enable = lib.mkDefault false;
  };
}
