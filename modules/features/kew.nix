{ self, ... }: {
  flake.homeManagerModules.kew = { config, pkgs, ... }: {
    home.packages = [ pkgs.kew ];

    xdg.configFile."kew/kewrc".text = ''
      [miscellaneous]
      path=${config.home.homeDirectory}/Music

      [colors]
      theme=dots
      # 2 = colours from the theme file, not from the album cover
      colorMode=2

      [track cover]
      coverEnabled=1
      # picks the kitty graphics protocol in kitty, falls back in a TTY
      coverStyle=auto
    '';

    xdg.configFile."kew/themes/dots.theme".text = let t = self.theme; in ''
      [theme]
      name=dots

      accent=${t.base09}
      text=${t.base06}
      textDim=${t.base05}
      textMuted=${t.base04}

      logo=${t.base04}
      header=${t.base04}
      footer=${t.base04}
      help=${t.base05}
      link=${t.base05}
      nowplaying=${t.base09}
      playbackstatus=${t.base04}

      playlist.rownum=${t.base04}
      playlist.title=${t.base06}
      playlist.playing=${t.base09}

      trackview.title=${t.base07}
      trackview.artist=${t.base05}
      trackview.album=${t.base04}
      trackview.year=${t.base04}
      trackview.time=${t.base04}
      trackview.visualizer=${t.base05}
      trackview.lyrics=${t.base05}

      library.artist=${t.base04}
      library.album=${t.base06}
      library.track=${t.base06}
      library.enqueued=${t.base05}
      library.playing=${t.base09}

      search.label=${t.base04}
      search.query=${t.base07}
      search.result=${t.base06}
      search.enqueued=${t.base05}
      search.playing=${t.base09}

      progress.filled=${t.base05}
      progress.empty=${t.base03}
      progress.elapsed=${t.base04}
      progress.duration=${t.base04}

      status.info=-1
      status.warning=${t.yellow}
      status.error=${t.red}
      status.success=${t.green}
    '';
  };
}
