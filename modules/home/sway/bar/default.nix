{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.sway.bar = {
    enable = lib.mkOption {
      description = "Whether to enable Swaybar.";
      default = false;
      type = lib.types.bool;
    };
  };

  config =
    let
      inherit (config.modules.sway) bar;
    in
    lib.mkIf (bar.enable && config.modules.sway.enable) {
      wayland.windowManager.sway.config.bars = [
        {
          command = "${pkgs.sway}/bin/swaybar";

          position = "bottom";

          statusCommand = "${pkgs.i3status}/bin/i3status";
          mode = "dock";
          trayOutput = "none";
          workspaceButtons = true;
          extraConfig = "separator_symbol \"|\"";

          fonts = {
            names = [
              config.modules.sway.fonts.monospace
            ];
            style = "Regular";
            size = 12.0;
          };

          colors = {
            activeWorkspace = {
              background = "#000000";
              border = "#ffffff";
              text = "#ffffff";
            };
            background = "#000000";
            focusedWorkspace = {
              background = "#ffffff";
              border = "#ffffff";
              text = "#000000";
            };
            inactiveWorkspace = {
              background = "#000000";
              border = "#000000";
              text = "#ffffff";
            };
            separator = "#ffffff";
            statusline = "#ffffff";
            urgentWorkspace = {
              background = "#000000";
              border = "#da8b8b";
              text = "#ffffff";
            };
          };
        }
      ];

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
              last_full_capacity = false;
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
