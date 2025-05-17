{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.fs.programs.git = {
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

  config = lib.mkIf config.fs.programs.git.enable {
    programs.git = {
      enable = true;
      package = pkgs.git;

      userName = config.fs.programs.git.name;
      userEmail = config.fs.programs.git.email;
      signing = lib.mkIf config.fs.programs.gpg.enable {
        key = config.fs.programs.gpg.primaryKey.fingerprint;
        signByDefault = true;
      };

      extraConfig = {
        init.defaultBranch = "master";
        pull.rebase = false;
      };
    };
  };
}
