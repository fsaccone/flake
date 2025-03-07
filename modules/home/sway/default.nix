{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./bar
  ];

  options.modules.sway = {
    enable = lib.mkOption {
      description = "Whether to enable the configuration for Sway.";
      default = false;
      type = lib.types.bool;
    };
    fonts = {
      monospace = lib.mkOption {
        type = lib.types.uniq lib.types.str;
        description = ''
          The monospace font to be used in Sway and its components.
        '';
      };
    };
  };

  config = lib.mkIf config.modules.sway.enable {
    wayland.windowManager.sway =
      let
        commands = {
          foot =
            let
              configFile = pkgs.writeText "foot.ini" ''
                [colors]
                background=000000
                foreground=ffffff

                [main]
                font=${config.modules.sway.fonts.monospace}:size=11
              '';
            in
            "${pkgs.foot}/bin/foot -c ${configFile}";
        };
      in
      {
        enable = true;
        package = pkgs.sway;

        config = {
          fonts = {
            names = [
              config.modules.sway.fonts.monospace
            ];
            style = "Regular";
            size = 12.0;
          };

          defaultWorkspace = "workspace number \"1\"";

          modifier = "Mod4";
          floating.modifier = "Mod4";

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
            "Mod4+Return" = "exec ${commands.foot}";

            "XF86AudioRaiseVolume" = ''
              exec ${pkgs.alsa-utils}/bin/amixer set Master 10%+
            '';
            "XF86AudioLowerVolume" = ''
              exec ${pkgs.alsa-utils}/bin/amixer set Master 10%-
            '';
            "XF86AudioMute" = ''
              exec ${pkgs.alsa-utils}/bin/amixer set Master toggle
            '';
            "XF86AudioMicMute" = ''
              exec ${pkgs.alsa-utils}/bin/amixer set Capture toggle
            '';

            "XF86MonBrightnessUp" = ''
              exec ${pkgs.brightnessctl}/bin/brightnessctl set 10%+
            '';
            "XF86MonBrightnessDown" = ''
              exec ${pkgs.brightnessctl}/bin/brightnessctl set 10%-
            '';

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
              command = commands.foot;
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
