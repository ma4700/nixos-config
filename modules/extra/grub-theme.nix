{ self, inputs, ... }: {
  flake.nixosModules.grub-theme = { pkgs, lib, ... }:
    let
      theme = self.theme;

      background = pkgs.runCommand "grub-bg.png" {
        nativeBuildInputs = [ pkgs.imagemagick ];
      } ''
        convert -size 1920x1080 xc:"${theme.base00}" -depth 8 png24:$out
      '';

      menuFont = pkgs.runCommand "grub-menu-font.pf2" {
        nativeBuildInputs = [ pkgs.grub2 ];
      } ''
        font=$(find ${pkgs.nerd-fonts.jetbrains-mono} -iname "*Regular*.ttf" | head -n1)
        grub-mkfont -s 20 -o $out "$font"
      '';

      grubTheme = pkgs.runCommand "grub-theme" {} ''
        mkdir -p $out
        cp ${background} $out/background.png
        cp ${menuFont} $out/menu.pf2

        cat > $out/theme.txt <<EOF
        desktop-image: "background.png"
        desktop-color: "${theme.base00}"
        title-text: ""
        terminal-font: "menu.pf2"

        + boot_menu {
          left = 15%
          top = 35%
          width = 70%
          height = 40%
          item_font = "menu.pf2"
          selected_item_font = "menu.pf2"
          item_color = "${theme.base06}"
          selected_item_color = "${theme.base09}"
          item_height = 32
          item_spacing = 6
          item_padding = 8
          icon_width = 0
          icon_height = 0
        }

        + progress_bar {
          id = "__timeout__"
          left = 15%
          top = 80%
          width = 70%
          height = 20
          font = "menu.pf2"
          text_color = "${theme.base04}"
          fg_color = "${theme.base09}"
          bg_color = "${theme.base02}"
          border_color = "${theme.base03}"
          show_text = true
          text = "@TIMEOUT_NOTIFICATION_MIDDLE@"
        }
        EOF
      '';
    in {
      boot.loader.grub.theme = grubTheme;
      boot.loader.grub.gfxmodeEfi = "1920x1080";
      boot.loader.grub.gfxmodeBios = "1920x1080";
      boot.loader.grub.splashImage = background;
      boot.loader.grub.backgroundColor = theme.base00;      
    };
}
