{ self, inputs, ... }: {

  flake.nixosModules.kitty = {
    # enables ncurses-based stuff (emacs, tmux, ...) to resolve $TERM,
    # they dont open otherwise
    environment.enableAllTerminfo = true;
  };

  perSystem = { pkgs, lib, self', ... }: {

    packages.myKitty = inputs.wrapper-modules.wrappers.kitty.wrap {
      inherit pkgs;

      font = {
        name = "JetBrainsMono Nerd Font";
        size = 12;
      };

      settings = let t = self.theme; in {
        scrollback_lines = 10000;
        enable_audio_bell = false;
        update_check_interval = 0;
        confirm_os_window_close = 0;
        window_padding_width = 6;
        hide_window_decorations = true;

        foreground = t.base06;
        background = t.base00;
        selection_foreground = t.base07;
        selection_background = t.base02;
        cursor = t.base06;
        cursor_text_color = t.base00;

        # ANSI palette: greys from the theme, colours muted to match them.
        # yellow is the amber accent, bright yellow the warning yellow.
        color0 = t.base00;   color8  = t.base04;
        color1 = t.red;      color9  = t.brightRed;
        color2 = t.green;    color10 = t.brightGreen;
        color3 = t.base09;   color11 = t.yellow;
        color4 = t.blue;     color12 = t.brightBlue;
        color5 = t.magenta;  color13 = t.brightMagenta;
        color6 = t.cyan;     color14 = t.brightCyan;
        color7 = t.base06;   color15 = t.base07;
      };

      keybindings = {
        "ctrl+shift+c" = "copy_to_clipboard";
        "ctrl+shift+v" = "paste_from_clipboard";
        "ctrl+shift+t" = "new_tab";
      };

      # anything the module doesn't have a typed option for yet
      extraConfig = ''
        # raw kitty.conf lines
      '';
    };

  };

}
