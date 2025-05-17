{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  imports = [ ./bar ];

  options.fs.programs.sway = {
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
    backgroundImage = lib.mkOption {
      description = "The image used as background.";
      type = lib.types.uniq lib.types.path;
    };
    colors = lib.mkOption {
      description = "The hex colors, in '#rrggbb[aa]' format.";
      type = lib.types.submodule {
        options = {
          background = lib.mkOption {
            description = ''
              The background color: it should be continous with the background
              image.
            '';
            type = lib.types.uniq lib.types.str;
          };
          foreground = lib.mkOption {
            description = "The foreground color.";
            type = lib.types.uniq lib.types.str;
          };
          darkRed = lib.mkOption {
            description = "The dark red color.";
            type = lib.types.uniq lib.types.str;
          };
          green = lib.mkOption {
            description = "The green color.";
            type = lib.types.uniq lib.types.str;
          };
          red = lib.mkOption {
            description = "The red color.";
            type = lib.types.uniq lib.types.str;
          };
          transparent = lib.mkOption {
            description = "The transparent color.";
            readOnly = true;
            default = "#00000000";
            type = lib.types.uniq lib.types.str;
          };
        };
      };
    };
  };

  config = lib.mkIf config.fs.programs.sway.enable {
    home = {
      packages = [
        pkgs.swaybg
        pkgs.wl-clipboard-rs
      ];
      pointerCursor = {
        gtk.enable = true;
        name = "graphite-dark-nord";
        package = pkgs.graphite-cursors;
        size = 20;
      };
    };

    wayland.windowManager.sway =
      let
        inherit (config.fs.programs.sway) backgroundImage colors;
        commands = {
          terminal =
            let
              # Remove the leading '#' character.
              parseColor = builtins.substring 1 7;

              background = parseColor colors.background;
              foreground = parseColor colors.foreground;

              configFile = pkgs.writeText "foot.ini" ''
                [cursor]
                color=${background} ${foreground}
                style=beam
                blink=yes
                blink-rate=500
                beam-thickness=1.5

                [colors]
                alpha=0.8
                background=${background}
                foreground=${foreground}

                [main]
                font=${config.fs.programs.sway.fonts.monospace}:size=11
                title=Foot
                locked-title=yes
              '';
            in
            "${pkgs.foot}/bin/foot -c ${configFile}";
        };
      in
      {
        enable = true;
        package = pkgs.sway;

        xwayland = true;
        config = {
          fonts = {
            names = [ config.fs.programs.sway.fonts.monospace ];
            style = "Regular";
            size = 12.0;
          };

          defaultWorkspace = "workspace number \"1\"";

          inherit (commands) terminal;
          modifier = "Mod4";
          floating.modifier = "Mod4";

          output."*".background = "${backgroundImage} fill";

          colors =
            let
              default = {
                background = colors.foreground;
                border = colors.transparent;
                text = colors.background;
              };
            in
            rec {
              focused = {
                background = colors.foreground;
                border = colors.foreground;
                text = colors.background;
              };

              focusedInactive = default;
              unfocused = default;
              urgent = {
                inherit (default) background text;
                border = colors.red;
              };
            }
            |> builtins.mapAttrs (
              name:
              {
                background,
                border,
                text,
              }:
              {
                inherit background border text;
                childBorder = border;
                indicator = border;
              }
            );

          gaps = {
            inner = 14;
            outer = 18;
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
              dwt = "disabled";
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
            "Mod4+Return" = "exec ${commands.terminal}";

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
