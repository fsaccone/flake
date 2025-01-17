{
  config,
  pkgs,
  ...
}:
{
  modules = {
    aerc.enable = true;
    firefox.enable = true;
    git.enable = true;
    gpg = {
      enable = true;
      primaryKey = {
        fingerprint = "42616543258F1BD93E84F0DB63A0ED9A00042E8C";
        url = "https://keys.openpgp.org/vks/v1/by-fingerprint/42616543258F1BD93E84F0DB63A0ED9A00042E8C";
        sha256 = "a833ae43e62b9b9b61e274e3749a4f870f46b7c99bf885e7b85fe4bedb244648";
      };
    };
    mediaViewers.enable = true;
    moneroWallet.enable = true;
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
  ];
}
