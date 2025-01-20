{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.system.sudo = {
    enable = lib.mkEnableOption "Enables sudo";
  };

  config = lib.mkIf config.modules.system.sudo.enable {
    security.sudo = {
      enable = true;
      package = pkgs.sudo;

      execWheelOnly = true;
      wheelNeedsPassword = true;
    };
  };
}
