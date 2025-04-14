{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.git = {
    enable = lib.mkOption {
      description = "Whether to enable Git.";
      default = false;
      type = lib.types.bool;
    };
    name = lib.mkOption {
      description = "The name used in commits.";
      type = lib.types.uniq lib.types.str;
    };
    email = lib.mkOption {
      description = "The email used in commits.";
      type = lib.types.uniq lib.types.str;
    };
  };

  config = lib.mkIf config.modules.git.enable {
    programs.git = {
      enable = true;
      package = pkgs.git;

      userName = config.modules.git.name;
      userEmail = config.modules.git.email;
      signing = lib.mkIf config.modules.gpg.enable {
        key = config.modules.gpg.primaryKey.fingerprint;
        signByDefault = true;
      };

      extraConfig = {
        init.defaultBranch = "master";
        pull.rebase = false;
      };
    };
  };
}
