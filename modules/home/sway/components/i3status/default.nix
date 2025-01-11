{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.sway.components = {
    i3status.enable = lib.mkEnableOption "Enables i3status";
  };

  config = lib.mkIf config.modules.sway.components.i3status.enable {
    programs.i3status = {
      enable = true;
      package = pkgs.i3status;

      enableDefault = false;
      general = {
        output_format = "i3bar";
        colors = true;
        color_good = "#80ff80";
        color_degraded = "#da8b8b";
        color_bad = "#c85151";
      };
      modules = {
        "wireless _first_" = {
          enable = true;
          position = 0;
          settings = {
            format_up = "WIR: %essid";
            format_down = "WIR: None";
          };
        };
        "battery all" = {
          enable = true;
          position = 1;
          settings = {
            format = "BAT: %percentage [%status]";
            format_down = "BAT: None";
            format_percentage = "%.01f%s";
            status_chr = "+";
            status_bat = "-";
            status_unk = "?";
            status_full = "F";
            status_idle = "I";
            low_threshold = 15;
            threshold_type = "percentage";
            last_full_capacity = true;
            path = "/sys/class/power_supply/BAT%d/uevent";
          };
        };
        "cpu_temperature 0" = {
          enable = true;
          position = 2;
          settings = {
            format = "CPU: %degrees°C";
            max_threshold = 75;
          };
        };
        "memory" = {
          enable = true;
          position = 3;
          settings = {
            format = "RAM: %percentage_used";
            threshold_degraded = "10%";
            threshold_critical = "5%";
            unit = "auto";
            decimals = 1;
          };
        };
        "time" = {
          enable = true;
          position = 4;
          settings = {
            format = "%Y-%m-%d %H:%M:%S %Z ";
          };
        };
      };
    };
  };
}
