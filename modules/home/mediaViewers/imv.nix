{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.mediaViewers = {
    imv.enable = lib.mkEnableOption "Enables imv";
  };

  config = lib.mkIf config.modules.mediaViewers.imv.enable {
    programs.imv = {
      enable = true;
      package = pkgs.imv;
    };
  };
}
