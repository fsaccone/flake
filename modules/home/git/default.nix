{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules = {
    git.enable = lib.mkEnableOption "Enables Git";
  };

  config = lib.mkIf config.modules.git.enable {
    programs.git = {
      enable = true;
      package = pkgs.git;

      userName = "Francesco Saccone";
      userEmail = "francesco@francescosaccone.com";
      signing = {
        signByDefault = true;
        key = "42616543258F1BD93E84F0DB63A0ED9A00042E8C";
      };
      extraConfig = {
        init.defaultBranch = "master";
      };
    };
  };
}
