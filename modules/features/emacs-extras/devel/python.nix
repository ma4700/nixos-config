{ self, inputs, ... }: {

  flake.homeManagerModules.emacs-extras.devel = { config, pkgs, lib, ... }: {
    config = {
      home.packages = with pkgs; [
        basedpyright
        ruff
        (python3.withPackages (ps: [ ps.debugpy ]))
      ];

      custom.emacs.extraInit = [ ./python.el ];

      custom.emacs.extraEmacsPackages = [
        (epkgs: [
          (epkgs.treesit-grammars.with-grammars (g: [ g.tree-sitter-python ]))
        ])
      ];

      xdg.configFile."direnv/templates/python-venv.envrc".source = ./python-venv.envrc;

      home.shellAliases = {
        envrc-python =
          "cp -n ${config.xdg.configHome}/direnv/templates/python-venv.envrc .envrc && direnv allow";
      };
    };
  };

}
