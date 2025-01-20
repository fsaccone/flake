{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules = {
    gpg = {
      enable = lib.mkEnableOption "Enables GnuPG";
      primaryKey = {
        fingerprint = lib.mkOption {
          type = lib.types.uniq lib.types.str;
          description = "The fingerprint of the primary key.";
        };
        url = lib.mkOption {
          type = lib.types.uniq lib.types.str;
          description = "The URL to the primary key file.";
        };
        sha256 = lib.mkOption {
          type = lib.types.uniq lib.types.str;
          description = "The SHA256 of the primary key file.";
        };
      };
    };
  };

  config = lib.mkIf config.modules.gpg.enable {
    programs.gpg = {
      enable = true;
      package = pkgs.gnupg;

      mutableKeys = false;
      mutableTrust = false;
      settings = {
        "pinentry-mode" = "loopback";
      };

      publicKeys = [
        {
          source = builtins.fetchurl {
            inherit (config.modules.gpg.primaryKey) url sha256;
          };
          trust = "ultimate";
        }
      ];
    };

    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      pinentryPackage = pkgs.pinentry-tty;
    };
  };
}
