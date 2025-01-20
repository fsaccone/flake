{
  config,
  pkgs,
  ...
}:
{
  modules = rec {
    aerc = {
      enable = true;
      email = {
        address = "francesco@francescosaccone.com";
        folders = {
          drafts = "Drafts";
          inbox = "INBOX";
          sent = "Sent";
          trash = "Trash";
        };
        imapHost = "glacier.mxrouting.net";
        imapTlsPort = 993;
        passwordCommand = ''
          ${pkgs.coreutils}/bin/cat ${./emailPassword.asc} | ${pkgs.gnupg}/bin/gpg --decrypt --recipient ${gpg.primaryKey.fingerprint}
        '';
        realName = "Francesco Saccone";
        smtpHost = "glacier.mxrouting.net";
        smtpTlsPort = 465;
        username = "francesco%40francescosaccone.com";
      };
    };
    firefox.enable = true;
    git = {
      enable = true;
      name = "Francesco Saccone";
      email = "francesco@francescosaccone.com";
    };
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
