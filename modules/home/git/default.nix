{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules = {
    git = {
      enable = lib.mkEnableOption "Enables Git";
      name = lib.mkOption {
        type = lib.types.uniq lib.types.str;
        description = "The name used in commits.";
      };
      email = lib.mkOption {
        type = lib.types.uniq lib.types.str;
        description = "The email used in commits.";
      };
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
      };
    };
  };
}
