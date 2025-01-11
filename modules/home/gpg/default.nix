{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules = {
    gpg.enable = lib.mkEnableOption "Enables GnuPG";
  };

  config = lib.mkIf config.modules.gpg.enable {
    programs.gpg = {
      enable = true;
      package = pkgs.gnupg;

      settings = {
        "pinentry-mode" = "loopback";
      };
    };

    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      pinentryPackage = pkgs.pinentry-tty;
    };
  };
}
