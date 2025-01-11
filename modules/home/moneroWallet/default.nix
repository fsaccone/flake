{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules = {
    moneroWallet.enable = lib.mkEnableOption "Enables Monero wallet";
  };

  config = lib.mkIf config.modules.moneroWallet.enable {
    home.packages = [
      pkgs.monero-gui
    ];

    home.file.".bitmonero/bitmonero.conf".source = ./dotfile.conf;
  };
}
