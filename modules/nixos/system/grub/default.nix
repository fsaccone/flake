{
  lib,
  options,
  config,
  ...
}:
{
  options.modules.system.grub = {
    enable = lib.mkEnableOption "Enables GNU GRUB";
  };

  config = lib.mkIf config.modules.system.grub.enable {
    boot.loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };
}
