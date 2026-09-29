{ self, inputs, ... }: {
  
  flake.nixosModules.niri = { pkgs, lib, ...}: {
    programs.niri = {
      enable = true;
    };
  };

  flake.homeManagerModules.niri = { pkgs, ... }: {
    home.packages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.myNiri
    ];
  };


  perSystem = { pkgs, lib, self', ... }: {
  
    packages.myNiri = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs;
      settings = {
        prefer-no-csd = true;
        spawn-at-startup = [
          (lib.getExe self'.packages.myNoctalia)
        ];

        layout = {
          gaps = 5;
          focus-ring = {
            width = 4;
            active-gradient = _: {
              props = {
                from = "#9dd67d";
                to = "#113800";
                angle = 180;
              };
            };
          };
        };

        input = {
          focus-follows-mouse = _:{};

          keyboard = {
            xkb = {
              layout = "us,gr";
            };
            repeat-rate = 40;
            repeat-delay = 250;
          };

          touchpad = {
            natural-scroll = _:{};
            tap = _:{};
          };

          mouse = {
            accel-profile = "flat";
          };
        };

        binds = {
          # "Mod+S".spawn-sh = 
          #  "${lib.getExe self'.packages.myNoctalia} ipc call launcher toggle";
          # "Mod+Q".close-window = _:{};
	  "Mod+Escape".spawn-sh =
	    "${lib.getExe self'.packages.myNoctalia} ipc call sessionMenu toggle";

          "Mod+Return".spawn-sh = lib.getExe self'.packages.myKitty;

          "Alt+Space".switch-layout = "next";

          "Mod+Q".close-window = _:{};
          "Mod+F".maximize-column = _:{};
          "Mod+G".fullscreen-window = _:{};
          "Mod+Shift+F".toggle-window-floating = _:{};
          "Mod+C".center-column = _:{};

          "Mod+H".focus-column-left = _:{};
          "Mod+L".focus-column-right = _:{};
          "Mod+K".focus-window-up = _:{};
          "Mod+J".focus-window-down = _:{};

          "Mod+Left".focus-column-left = _:{};
          "Mod+Right".focus-column-right = _:{};
          "Mod+Up".focus-window-up = _:{};
          "Mod+Down".focus-window-down = _:{};

          "Mod+Shift+H".move-column-left = _:{};
          "Mod+Shift+L".move-column-right = _:{};
          "Mod+Shift+K".move-window-up = _:{};
          "Mod+Shift+J".move-window-down = _:{};

          "Mod+1".focus-workspace =  1;
          "Mod+2".focus-workspace =  2;
          "Mod+3".focus-workspace =  3;
          "Mod+4".focus-workspace =  4;
          "Mod+5".focus-workspace =  5;
          "Mod+6".focus-workspace =  6;
          "Mod+7".focus-workspace =  7;
          "Mod+8".focus-workspace =  8;
          "Mod+9".focus-workspace =  9;

          "Mod+Shift+1".move-column-to-workspace =  1;
          "Mod+Shift+2".move-column-to-workspace =  2;
          "Mod+Shift+3".move-column-to-workspace =  3;
          "Mod+Shift+4".move-column-to-workspace =  4;
          "Mod+Shift+5".move-column-to-workspace =  5;
          "Mod+Shift+6".move-column-to-workspace =  6;
          "Mod+Shift+7".move-column-to-workspace =  7;
          "Mod+Shift+8".move-column-to-workspace =  8;
          "Mod+Shift+9".move-column-to-workspace =  9;

          "Mod+S".spawn-sh = 
            "${lib.getExe self'.packages.myNoctalia} ipc call launcher toggle";
          #"Mod+V".spawn-sh = ''${config.pkgs.alsa-utils}/bin/amixer sset Capture toggle'';

          "XF86AudioRaiseVolume".spawn-sh = "wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+";
          "XF86AudioLowerVolume".spawn-sh = "wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-";

          "Mod+Ctrl+H".set-column-width = "-5%";
          "Mod+Ctrl+L".set-column-width = "+5%";
          "Mod+Ctrl+J".set-window-height = "-5%";
          "Mod+Ctrl+K".set-window-height = "+5%";

          "Mod+WheelScrollDown".focus-column-left = _:{};
          "Mod+WheelScrollUp".focus-column-right = _:{};
          "Mod+Ctrl+WheelScrollDown".focus-workspace-down = _:{};
          "Mod+Ctrl+WheelScrollUp".focus-workspace-up = _:{};

          # "Mod+Ctrl+S".spawn-sh = ''${lib.getExe config.pkgs.grim} -l 0 - | ${config.pkgs.wl-clipboard}/bin/wl-copy'';

          # "Mod+Shift+E".spawn-sh = ''${config.pkgs.wl-clipboard}/bin/wl-paste | ${lib.getExe config.pkgs.swappy} -f -'';

          # "Mod+Shift+S".spawn-sh = lib.getExe (config.pkgs.writeShellApplication {
          #   name = "screenshot";
          #   text = ''
          #     ${lib.getExe config.pkgs.grim} -g "$(${lib.getExe config.pkgs.slurp} -w 0)" - \
          #     | ${config.pkgs.wl-clipboard}/bin/wl-copy
          #   '';
          # });
          #
          # "Mod+d".spawn-sh = self.mkWhichKeyExe config.pkgs [
          #   {
          #     key = "b";
          #     desc = "Bluetooth";
          #     cmd = "${lib.getExe self'.packages.myNoctalia} ipc call bluetooth togglePanel";
          #   }
          #   {
          #     key = "w";
          #     desc = "Wifi";
          #     cmd = "${lib.getExe self'.packages.myNoctalia} ipc call wifi togglePanel";
          #   }
          #   {
          #     key = "f";
          #     desc = "Firefox";
          #     cmd = "firefox";
          #   }
          #   {
          #     key = "t";
          #     desc = "Telegram";
          #     cmd = "Telegram";
          #   }
          #   {
          #     key = "d";
          #     desc = "Discord";
          #     cmd = "vesktop";
          #   }
          #   {
          #     key = "m";
          #     desc = "Youtube Music";
          #     cmd = "pear-desktop";
          #   }
          #   {
          #     key = "s";
          #     desc = "Pavucontrol";
          #     cmd = "${lib.getExe pkgs.pavucontrol}";
          #   }
          # ];
        };
      };
    };

  };

}
