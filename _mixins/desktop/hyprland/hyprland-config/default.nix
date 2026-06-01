{
  config,
  lib,
  pkgs,
  ...
}:
let
  workspaceBinds = lib.concatMap (
    i:
    let
      key = toString (lib.mod i 10);
    in
    [
      {
        _args = [
          "SUPER + ${key}"
          (lib.generators.mkLuaInline "hl.dsp.focus({ workspace = \"${toString i}\" })")
        ];
      }
      {
        _args = [
          "SUPER + SHIFT + ${key}"
          (lib.generators.mkLuaInline "hl.dsp.window.move({ workspace = \"${toString i}\" })")
        ];
      }
    ]
  ) (lib.range 1 10);
in
{
  # This is primarily the wayblue Hyprland config
  # https://wiki.hyprland.org/Configuring/
  wayland.windowManager.hyprland = {
    configType = "lua";
    settings = {
      mod = {
        _var = "SUPER";
      };
      fileManager = {
        _var = lib.getExe pkgs.kdePackages.dolphin;
      };
      lockCommand = {
        _var = "loginctl lock-session";
      };
      menu = {
        _var = "${lib.getExe config.programs.wofi.package} --show drun";
      };
      terminal = {
        _var = lib.getExe pkgs.foot;
      };

      config = {
        general = {
          gaps_in = 5;
          gaps_out = 20;

          border_size = 2;

          # https://wiki.hyprland.org/Configuring/Variables/#variable-types for info about colors
          # 45deg?
          # rgba(00ff99ee)
          col = {
            active_border = {
              colors = [
                "rgba(33ccffee)"
                "rgba(00ff99ee)"
              ];
              angle = 45;
            };
            inactive_border = "rgba(595959aa)";
          };

          # Set to true enable resizing windows by clicking and dragging on borders and gaps
          resize_on_border = false;

          # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
          allow_tearing = false;

          layout = "dwindle";
        };

        # https://wiki.hyprland.org/Configuring/Variables/#decoration
        decoration = {
          rounding = 10;
          rounding_power = 2;

          # Change transparency of focused and unfocused windows
          active_opacity = 1.0;
          inactive_opacity = 1.0;

          shadow = {
            enabled = true;
            range = 4;
            render_power = 3;
            color = "0xee1a1a1a";
          };

          # https://wiki.hyprland.org/Configuring/Variables/#blur
          blur = {
            enabled = true;
            size = 3;
            passes = 1;

            vibrancy = 0.1696;
          };
        };

        animations = {
          enabled = true;
        };

        # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
        dwindle = {
          preserve_split = true; # You probably want this
        };

        # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
        master = {
          new_status = "master";
        };

        scrolling = {
          fullscreen_on_one_column = true;
        };

        # https://wiki.hyprland.org/Configuring/Variables/#misc
        misc = {
          force_default_wallpaper = -1; # Set to 0 or 1 to disable the anime mascot wallpapers
          disable_hyprland_logo = false; # If true disables the random hyprland logo / anime girl background. :(
        };

        # https://wiki.hyprland.org/Configuring/Variables/#input
        input = {
          kb_layout = "us";
          # kb_variant = "";
          # kb_model = "";
          # kb_options = "";
          # kb_rules = "";

          follow_mouse = 1;

          sensitivity = 0; # -1.0 - 1.0, 0 means no modification.

          touchpad = {
            natural_scroll = false;
          };
        };
      };

      # Default curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
      curve = [
        {
          _args = [
            "easeOutQuint"
            {
              type = "bezier";
              points = lib.generators.mkLuaInline "{ {0.23, 1}, {0.32, 1} }";
            }
          ];
        }
        {
          _args = [
            "easeInOutCubic"
            {
              type = "bezier";
              points = lib.generators.mkLuaInline "{ {0.65, 0.05}, {0.36, 1} }";
            }
          ];
        }
        {
          _args = [
            "linear"
            {
              type = "bezier";
              points = lib.generators.mkLuaInline "{ {0, 0}, {1, 1} }";
            }
          ];
        }
        {
          _args = [
            "almostLinear"
            {
              type = "bezier";
              points = lib.generators.mkLuaInline "{ {0.5, 0.5}, {0.75, 1} }";
            }
          ];
        }
        {
          _args = [
            "quick"
            {
              type = "bezier";
              points = lib.generators.mkLuaInline "{ {0.15, 0}, {0.1, 1} }";
            }
          ];
        }

        # Default springs
        {
          _args = [
            "easy"
            {
              type = "spring";
              mass = 1;
              stiffness = 71.2633;
              dampening = 15.8273644;
              points = lib.generators.mkLuaInline "{ {0.15, 0}, {0.1, 1} }";
            }
          ];
        }
      ];

      animation = [
        {
          leaf = "global";
          enabled = true;
          speed = 10;
          bezier = "default";
        }
        {
          leaf = "border";
          enabled = true;
          speed = 5.39;
          bezier = "easeOutQuint";
        }
        {
          leaf = "windows";
          enabled = true;
          speed = 4.79;
          bezier = "easy";
        }
        {
          leaf = "windowsIn";
          enabled = true;
          speed = 4.1;
          bezier = "easy";
          style = "popin 87%";
        }
        {
          leaf = "windowsOut";
          enabled = true;
          speed = 1.49;
          bezier = "";
          style = "popin 87%";
        }
        {
          leaf = "fadeIn";
          enabled = true;
          speed = 1.73;
          bezier = "almostLinear";
        }
        {
          leaf = "fadeOut";
          enabled = true;
          speed = 1.46;
          bezier = "almostLinear";
        }
        {
          leaf = "fade";
          enabled = true;
          speed = 3.03;
          bezier = "quick";
        }
        {
          leaf = "layers";
          enabled = true;
          speed = 3.81;
          bezier = "easeOutQuint";
        }
        {
          leaf = "layersIn";
          enabled = true;
          speed = 4;
          bezier = "easeOutQuint";
          style = "fade";
        }
        {
          leaf = "layersOut";
          enabled = true;
          speed = 1.5;
          bezier = "linear";
          style = "fade";
        }
        {
          leaf = "fadeLayersIn";
          enabled = true;
          speed = 1.79;
          bezier = "almostLinear";
        }
        {
          leaf = "fadeLayersOut";
          enabled = true;
          speed = 1.39;
          bezier = "almostLinear";
        }
        {
          leaf = "workspaces";
          enabled = true;
          speed = 1.94;
          bezier = "almostLinear";
          style = "fade";
        }
        {
          leaf = "workspacesIn";
          enabled = true;
          speed = 1.21;
          bezier = "almostLinear";
          style = "fade";
        }
        {
          leaf = "workspacesOut";
          enabled = true;
          speed = 1.94;
          bezier = "almostLinear";
          style = "fade";
        }
        {
          leaf = "zoomFactor";
          enabled = true;
          speed = 7;
          bezier = "quick";
        }
      ];

      env = [
        {
          _args = [
            "XCURSOR_SIZE"
            "24"
          ];
        }
        {
          _args = [
            "HYPRCURSOR_SIZE"
            "24"
          ];
        }
      ];

      gesture = [
        (lib.generators.mkLuaInline "{ fingers = 3, direction = \"horizontal\", action = \"workspace\" }")
      ];

      ###################
      ### KEYBINDINGS ###
      ###################

      # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
      bind = [
        {
          _args = [
            "SUPER + Q"
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd(terminal)")
          ];
        }
        {
          _args = [
            "SUPER + C"
            # killactive
            (lib.generators.mkLuaInline "hl.dsp.window.close()")
          ];
        }
        {
          _args = [
            "SUPER + M"
            (lib.generators.mkLuaInline "hl.dsp.exit()")
          ];
        }
        {
          _args = [
            "SUPER + E"
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd(fileManager)")
          ];
        }
        {
          _args = [
            "SUPER + V"
            (lib.generators.mkLuaInline "hl.dsp.window.float({ action = \"toggle\" })")
          ];
        }
        {
          _args = [
            "SUPER + R"
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd(menu)")
          ];
        }
        {
          _args = [
            "SUPER + P"
            (lib.generators.mkLuaInline "hl.dsp.window.pseudo()")
          ];
        }
        {
          _args = [
            "SUPER + F"
            (lib.generators.mkLuaInline "hl.dsp.window.fullscreen()")
          ];
        }
        {
          _args = [
            "SUPER + L"
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd(lockCommand)")
          ];
        }

        # Move focus with mainMod + arrow keys
        {
          _args = [
            "SUPER + left"
            (lib.generators.mkLuaInline "hl.dsp.focus({ direction = \"left\" })")
          ];
        }
        {
          _args = [
            "SUPER + right"
            (lib.generators.mkLuaInline "hl.dsp.focus({ direction = \"right\" })")
          ];
        }
        {
          _args = [
            "SUPER + up"
            (lib.generators.mkLuaInline "hl.dsp.focus({ direction = \"up\" })")
          ];
        }
        {
          _args = [
            "SUPER + down"
            (lib.generators.mkLuaInline "hl.dsp.focus({ direction = \"down\" })")
          ];
        }

        # Switch workspaces with mainMod + [0-9]
        # "SUPER, 1, workspace, 1"
        # "SUPER, 2, workspace, 2"
        # "SUPER, 3, workspace, 3"
        # "SUPER, 4, workspace, 4"
        # "SUPER, 5, workspace, 5"
        # "SUPER, 6, workspace, 6"
        # "SUPER, 7, workspace, 7"
        # "SUPER, 8, workspace, 8"
        # "SUPER, 9, workspace, 9"
        # "SUPER, 0, workspace, 10"

        # # Move active window to a workspace with mainMod + SHIFT + [0-9]
        # "SUPER SHIFT, 1, movetoworkspace, 1"
        # "SUPER SHIFT, 2, movetoworkspace, 2"
        # "SUPER SHIFT, 3, movetoworkspace, 3"
        # "SUPER SHIFT, 4, movetoworkspace, 4"
        # "SUPER SHIFT, 5, movetoworkspace, 5"
        # "SUPER SHIFT, 6, movetoworkspace, 6"
        # "SUPER SHIFT, 7, movetoworkspace, 7"
        # "SUPER SHIFT, 8, movetoworkspace, 8"
        # "SUPER SHIFT, 9, movetoworkspace, 9"
        # "SUPER SHIFT, 0, movetoworkspace, 10"

        # Example special workspace (scratchpad)
        # "SUPER, S, togglespecialworkspace, magic"
        # "SUPER SHIFT, S, movetoworkspace, special:magic"

        # Scroll through existing workspaces with mainMod + scroll
        {
          _args = [
            "SUPER + mouse_down"
            (lib.generators.mkLuaInline "hl.dsp.focus({ workspace = \"e+1\" })")
          ];
        }
        {
          _args = [
            "SUPER + mouse_up"
            (lib.generators.mkLuaInline "hl.dsp.focus({ workspace = \"e-1\" })")
          ];
        }

        {
          _args = [
            "SUPER + O"
            (lib.generators.mkLuaInline "hl.dsp.submap(\"resize\")")
          ];
        }

        # Move/resize windows with mainMod + LMB/RMB and dragging
        {
          _args = [
            "SUPER + mouse:272"
            (lib.generators.mkLuaInline "hl.dsp.window.drag()")
            { mouse = true; }
          ];
        }
        {
          _args = [
            "SUPER + mouse:273"
            (lib.generators.mkLuaInline "hl.dsp.window.resize()")
            { mouse = true; }
          ];
        }

        # Laptop multimedia keys for volume and LCD brightness
        {
          _args = [
            "XF86AudioRaiseVolume"
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${lib.getBin pkgs.wireplumber}/bin/wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+\")")
            {
              locked = true;
              repeating = true;
            }
          ];
        }
        {
          _args = [
            "XF86AudioLowerVolume"
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${lib.getBin pkgs.wireplumber}/bin/wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%-\")")
            {
              locked = true;
              repeating = true;
            }
          ];
        }
        {
          _args = [
            "XF86AudioMute"
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${lib.getBin pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle\")")
            { locked = true; }
          ];
        }
        {
          _args = [
            "XF86AudioMicMute"
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${lib.getBin pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle\")")
            { locked = true; }
          ];
        }
        {
          _args = [
            "XF86MonBrightnessUp"
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${lib.getExe pkgs.brightnessctl} s 10%+\")")
            {
              locked = true;
              repeating = true;
            }
          ];
        }
        {
          _args = [
            "XF86MonBrightnessDown"
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${lib.getExe pkgs.brightnessctl} s 10%-\")")
            {
              locked = true;
              repeating = true;
            }
          ];
        }
        {
          _args = [
            "XF86AudioNext"
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${lib.getExe pkgs.playerctl} next\")")
            { locked = true; }
          ];
        }
        {
          _args = [
            "XF86AudioPause"
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${lib.getExe pkgs.playerctl} play-pause\")")
            { locked = true; }
          ];
        }
        {
          _args = [
            "XF86AudioPlay"
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${lib.getExe pkgs.playerctl} play-pause\")")
            { locked = true; }
          ];
        }
        {
          _args = [
            "XF86AudioPrev"
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${lib.getExe pkgs.playerctl} previous\")")
            { locked = true; }
          ];
        }
      ]
      ++ workspaceBinds;

      ##############################
      ### WINDOWS AND WORKSPACES ###
      ##############################

      # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
      # See https://wiki.hyprland.org/Configuring/Workspace-Rules/ for workspace rules

      # Example windowrule

      window_rule = [
        # Ignore maximize requests from apps. You'll probably like this.
        {
          match.class = ".*";
          suppress_event = "maximize";
        }
        # Fix some dragging issues with XWayland
        {
          match = {
            xwayland = true;
            float = true;
            fullscreen = false;
            pin = false;
          };
          no_focus = true;
        }
        {
          match.class = "hyprland-run";
          move = "20 monitor_h-120";
          float = true;
        }
        # Prevent the Firefox file dialog from getting cut off.
        {
          match = {
            class = "^(org.mozilla.firefox)$";
            title = "^(Enter name of file to save to…)(.*)$";
          };
          float = true;
          center = true;
          size = "{\"monitor_w*0.9\", \"monitor_h*0.9\"}";
        }
      ];

      define_submap = [
        {
          _args = [
            "resize"
            (lib.generators.mkLuaInline "function()\n  hl.bind(\"right\", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })\n  hl.bind(\"left\", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })\n  hl.bind(\"escape\", hl.dsp.submap(\"reset\"))\nend")
          ];
        }
      ];
      # submaps = {
      #   resize = {
      #     settings = {
      #       bind = [
      #         # Use `reset` to go back to the global submap
      #         ", escape, submap, reset"
      #       ];
      #       # Set repeatable binds for resizing the active window.
      #       binde = [
      #         ", right, resizeactive, 10 0"
      #         ", left, resizeactive, -10 0"
      #         ", up, resizeactive, 0 -10"
      #         ", down, resizeactive, 0 10"
      #       ];
      #     };
      #   };
      # };
    };
  };
}
