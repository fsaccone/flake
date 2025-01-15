{
  config,
  pkgs,
  ...
}:
{
  modules = {
    firefox.enable = true;
    git.enable = true;
    gpg.enable = true;
    mediaViewers.enable = true;
    moneroWallet.enable = true;
    neomutt.enable = true;
    neovim.enable = true;
    sway.enable = true;
    syncthing.enable = true;
  };

  home.packages = with pkgs; [
    ardour
    helvum
    keepassxc
    libreoffice
    musescore
    qjackctl
    rsync
    thunderbird
  ];
}
