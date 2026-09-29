{ self, inputs, ... }: {
  # Turn on both system and user hyprland module
  flake.nixosModules.hyprland = { pkgs, lib, ... }: {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    
    # PAM service used by quickshell lock screen (Lock.qml)
    security.pam.services.quickshell-lock = { };
  };



  # Staying off configType = "lua" for now, it breaks on "$mod" style
  # settings (home-manager#9468). Revisit later.
  flake.homeManagerModules.hyprland = { pkgs, lib, ... }: {
    home.pointerCursor = {
      enable = true;
      package = pkgs.phinger-cursors;
      name = "phinger-cursors-light";
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };

    # Locks the screen before any suspend (lid close included). inhibit_sleep = 3
    # makes logind wait until the lock is up, so nothing flashes on resume.
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.myQuickshell} ipc call lock lock";
          before_sleep_cmd = "${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.myQuickshell} ipc call lock lock";
          after_sleep_cmd = "hyprctl dispatch dpms on";
          inhibit_sleep = 3;
        };
      };
    };


    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = true;
      configType = "hyprlang";

      settings = {
        "$mod" = "SUPER";
        "$term" = lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.myKitty;
        "$shell" = lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.myQuickshell;

        exec-once = [
          "$shell"
        ];

        monitor = [
          ",preferred,auto,1"
        ];

        general = {
          gaps_in = 5;
          gaps_out = 5;
          border_size = 2;
          "col.active_border" = "rgba(${self.themeNoHash.base07}ee) rgba(${self.themeNoHash.base03}00) 45deg";
          "col.inactive_border" = "rgba(${self.themeNoHash.base02}80)";
          layout = "dwindle";
          allow_tearing = false;
        };

        cursor.inactive_timeout = 0;

        decoration = {
          rounding = 0;
          blur.enabled = false;
          shadow.enabled = false;
        };

        animations.enabled = false;

        dwindle.preserve_split = true;

        # prevent kitty (and any other apps) from fullscreen after opening
        windowrule = [
          "match:class .*, suppress_event maximize"
        ];

        input = {
          kb_layout = "us,gr";
          repeat_rate = 40;
          repeat_delay = 250;
          follow_mouse = 1;
          accel_profile = "flat";

          touchpad = {
            natural_scroll = true;
            tap-to-click = true;
          };
        };

        misc = {
          disable_hyprland_logo = true;
          # lets the lockscreen be restarted if quickshell crashes
          allow_session_lock_restore = true;
        };

        ecosystem.no_update_news = true;

        bind = [
          "$mod, Return, exec, $term"
          "$mod, Q, killactive,"
          "$mod, F, fullscreen, 1"
          "$mod, G, fullscreen, 0"
          "$mod SHIFT, F, togglefloating,"
          "$mod, C, centerwindow,"
          "$mod, N, exec, $shell ipc call notifications toggle"
          "$mod, D, exec, $shell ipc call launcher toggle"
          "$mod, Escape, exec, $shell ipc call session toggle"

         "ALT, Space, exec, hyprctl switchxkblayout current next"

          "$mod, H, movefocus, l"
          "$mod, L, movefocus, r"
          "$mod, K, movefocus, u"
          "$mod, J, movefocus, d"

          "$mod SHIFT, H, movewindow, l"
          "$mod SHIFT, L, movewindow, r"
          "$mod SHIFT, K, movewindow, u"
          "$mod SHIFT, J, movewindow, d"

          "$mod, 1, workspace, 1"
          "$mod, 2, workspace, 2"
          "$mod, 3, workspace, 3"
          "$mod, 4, workspace, 4"
          "$mod, 5, workspace, 5"
          "$mod, 6, workspace, 6"
          "$mod, 7, workspace, 7"
          "$mod, 8, workspace, 8"
          "$mod, 9, workspace, 9"

          "$mod SHIFT, 1, movetoworkspace, 1"
          "$mod SHIFT, 2, movetoworkspace, 2"
          "$mod SHIFT, 3, movetoworkspace, 3"
          "$mod SHIFT, 4, movetoworkspace, 4"
          "$mod SHIFT, 5, movetoworkspace, 5"
          "$mod SHIFT, 6, movetoworkspace, 6"
          "$mod SHIFT, 7, movetoworkspace, 7"
          "$mod SHIFT, 8, movetoworkspace, 8"
          "$mod SHIFT, 9, movetoworkspace, 9"

          "$mod CTRL, H, resizeactive, -40 0"
          "$mod CTRL, L, resizeactive, 40 0"
          "$mod CTRL, K, resizeactive, 0 -40"
          "$mod CTRL, J, resizeactive, 0 40"

          "$mod, mouse_down, workspace, e+1"
          "$mod, mouse_up, workspace, e-1"
        ];

        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];

        binde = [
          ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"
          ", XF86AudioLowerVolume, exec, wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"
        ];
      };
    };
  };
}
