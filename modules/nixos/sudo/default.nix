{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.sudo = {
    enable = lib.mkEnableOption "Enables sudo";
  };

  config = lib.mkIf config.modules.sudo.enable {
    security.sudo = {
      enable = true;
      package = pkgs.sudo;

      execWheelOnly = true;
      wheelNeedsPassword = true;
    };
  };
}
