{ self, inputs, ... }: {

  flake.homeManagerModules.emacs-extras.latex = { config, pkgs, lib, ... }: {
    options.custom.latex.autoInsertTemplate = lib.mkOption {
      type = lib.types.path;
      default = ./templates/lecture-notes.tex;
      description = ''
        Template file auto-inserted into the new, empty .tex
        buffers.
      '';
    };

    config = {
      home.packages = [
        (pkgs.texliveSmall.withPackages (ps: with ps; [
          latexmk
          mathtools
          physics
          siunitx
          mhchem
          listings
          xetex
          polyglossia
          preview
          dvisvgm
          unicode-math
          hyphen-greek
        ]))
        pkgs.libertinus
      ];

      fonts.fontconfig.enable = true;

      programs.zathura = {
        enable = true;
        extraConfig = builtins.readFile ./zathurarc;
      };

      xdg.configFile = {
        "emacs/snippets/LaTeX-mode".source = ./snippets/LaTeX-mode;
        "emacs/templates/auto".source = ./templates/auto;
        "emacs/templates/lecture-notes.tex".source =
          config.custom.latex.autoInsertTemplate;
      };

      custom.emacs.extraInit = [ ./latex.el ];
    };
  };

}
