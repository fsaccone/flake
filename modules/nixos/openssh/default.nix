{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules = {
    openssh.enable = lib.mkEnableOption "Enables OpenSSH";
  };

  config = lib.mkIf config.modules.openssh.enable {
    services.openssh = {
      enable = true;
    };

    programs.ssh = {
      startAgent = true;
      package = pkgs.openssh;
    };
  };
}
