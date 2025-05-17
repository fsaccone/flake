{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.fs.programs.pass = {
    enable = lib.mkOption {
      description = "Whether to enable Password Store.";
      default = false;
      type = lib.types.bool;
    };
    directory = lib.mkOption {
      description = "The directory containing the encrypted passwords.";
      default = "${config.home.homeDirectory}/.password-store";
      readOnly = true;
      type = lib.types.uniq lib.types.path;
    };
    passwordStoreDirectory = lib.mkOption {
      description = ''
        The directory the password store directory will symlink to.
      '';
      type = lib.types.uniq lib.types.path;
    };
  };

  config = lib.mkIf config.fs.programs.pass.enable {
    programs.password-store = {
      enable = true;
      package = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
      settings = {
        PASSWORD_STORE_DIR = config.fs.programs.pass.directory;
        PASSWORD_STORE_CLIP_TIME = "15";
      };
    };

    home.file = {
      ".password-store" = {
        source = config.fs.programs.pass.passwordStoreDirectory;
      };
    };

    home.packages = [ pkgs.wl-clipboard-rs ];
  };
}
