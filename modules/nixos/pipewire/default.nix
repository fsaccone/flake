{
  lib,
  options,
  config,
  ...
}:
{
  options.modules.pipewire = {
    enable = lib.mkEnableOption "Enables PipeWire";
  };

  config = lib.mkIf config.modules.pipewire.enable {
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;

      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      jack.enable = true;
    };
  };
}
