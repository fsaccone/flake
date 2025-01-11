{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./components/alacritty
    ./components/i3status
  ];

  options.modules.sway = {
    enable = lib.mkEnableOption "enables sway configuration";
  };

  config = lib.mkIf config.modules.sway.enable {
    modules.sway.components = {
      alacritty.enable = lib.mkDefault true;
      i3status.enable = lib.mkDefault true;
    };

    wayland.windowManager.sway = {
      enable = true;
      package = pkgs.sway;

      config = {
        fonts = {
          names = [
            "IBM Plex Mono"
          ];
          style = "Regular";
          size = 12.0;
        };

        defaultWorkspace = "workspace number \"1\"";

        modifier = "Mod4";
        floating.modifier = "Mod4";

        bars = [
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
                "IBM Plex Mono"
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

        colors = {
          background = "#ffffff";
          focused = {
            background = "#ffffff";
            border = "#ffffff";
            childBorder = "#ffffff";
            indicator = "#ffffff";
            text = "#000000";
          };
          placeholder = {
            background = "#ffffff";
            border = "#000000";
            childBorder = "#ffffff";
            indicator = "#ffffff";
            text = "#000000";
          };
          unfocused = {
            background = "#000000";
            border = "#000000";
            childBorder = "#000000";
            indicator = "#000000";
            text = "#ffffff";
          };
          urgent = {
            background = "#000000";
            border = "#da8b8b";
            childBorder = "#000000";
            indicator = "#000000";
            text = "#ffffff";
          };
        };

        gaps = {
          bottom = 7;
          left = 7;
          right = 7;
          top = 7;

          inner = 7;
        };

        window = {
          titlebar = false;
        };

        input = {
          "type:keyboard" = {
            xkb_layout = "it";
          };
          "*" = {
            tap = "enabled";
          };
        };

        modes.resize = {
          "Up" = "resize grow height 7 px or 7 ppt";
          "Right" = "resize grow width 7 px or 7 ppt";
          "Left" = "resize shrink width 7 px or 7 ppt";
          "Down" = "resize shring height 7 px or 7 ppt";

          "Mod4+r" = "mode \"default\"";
        };

        keybindings = {
          "Mod4+Return" = "exec ${pkgs.alacritty}/bin/alacritty";
          "Mod4+p" = ''
            exec ${pkgs.j4-dmenu-desktop}/bin/j4-dmenu-desktop --no-generic --term alacritty \
            --dmenu='${pkgs.dmenu}/bin/dmenu -i -l 0 -p ">" -fn "IBM Plex Mono-14" -nb "#000000" -nf \
            "#ffffff" -sb "#ffffff" -sf "#000000"'
          '';

          "XF86AudioRaiseVolume" = "exec ${pkgs.alsa-utils}/bin/amixer set Master 10%+";
          "XF86AudioLowerVolume" = "exec ${pkgs.alsa-utils}/bin/amixer set Master 10%-";
          "XF86AudioMute" = "exec ${pkgs.alsa-utils}/bin/amixer set Master toggle";
          "XF86AudioMicMute" = "exec ${pkgs.alsa-utils}/bin/amixer set Capture toggle";

          "XF86MonBrightnessUp" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 10%+¬";
          "XF86MonBrightnessDown" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 10%-";

          "Mod4+q" = "kill";

          "Mod4+Left" = "focus left";
          "Mod4+Down" = "focus down";
          "Mod4+Up" = "focus up";
          "Mod4+Right" = "focus right";

          "Mod4+Shift+Left" = "move left";
          "Mod4+Shift+Down" = "move down";
          "Mod4+Shift+Up" = "move up";
          "Mod4+Shift+Right" = "move right";

          "Mod4+f" = "fullscreen toggle";
          "Mod4+Shift+space" = "floating toggle";
          "Mod4+space" = "focus mode_toggle";

          "Mod4+1" = "workspace number \"1\"";
          "Mod4+2" = "workspace number \"2\"";
          "Mod4+3" = "workspace number \"3\"";
          "Mod4+4" = "workspace number \"4\"";
          "Mod4+5" = "workspace number \"5\"";
          "Mod4+6" = "workspace number \"6\"";
          "Mod4+7" = "workspace number \"7\"";
          "Mod4+8" = "workspace number \"8\"";
          "Mod4+9" = "workspace number \"9\"";
          "Mod4+0" = "workspace number \"10\"";

          "Mod4+Shift+1" = "move container to workspace number \"1\"";
          "Mod4+Shift+2" = "move container to workspace number \"2\"";
          "Mod4+Shift+3" = "move container to workspace number \"3\"";
          "Mod4+Shift+4" = "move container to workspace number \"4\"";
          "Mod4+Shift+5" = "move container to workspace number \"5\"";
          "Mod4+Shift+6" = "move container to workspace number \"6\"";
          "Mod4+Shift+7" = "move container to workspace number \"7\"";
          "Mod4+Shift+8" = "move container to workspace number \"8\"";
          "Mod4+Shift+9" = "move container to workspace number \"9\"";
          "Mod4+Shift+0" = "move container to workspace number \"10\"";

          "Mod4+Shift+c" = "reload";
          "Mod4+Shift+r" = "restart";

          "Mod4+r" = "mode \"resize\"";
        };

        startup = [
          {
            command = "${pkgs.autotiling}/bin/autotiling";
            always = true;
          }
          {
            command = "${pkgs.alacritty}/bin/alacritty";
            always = false;
          }
          {
            command = "${pkgs.alsa-utils}/bin/amixer set Master 100%";
            always = false;
          }
          {
            command = "${pkgs.alsa-utils}/bin/amixer set Capture 100%";
            always = false;
          }
          {
            command = "${pkgs.brightnessctl}/bin/brightnessctl set 100%";
            always = false;
          }
        ];
      };
    };
  };
}
