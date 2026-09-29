{ self, inputs, ... }: {

  flake.homeManagerModules.emacs = { config, pkgs, lib, ... }: {
    options.custom.emacs = {
      package = lib.mkOption {
        type = lib.types.package;
        default = self.legacyPackages.${pkgs.stdenv.hostPlatform.system}.mkEmacs {
          extraInit = config.custom.emacs.extraInit;
          extraEmacsPackages = config.custom.emacs.extraEmacsPackages;
        };        
        description = ''
          Which built Emacs package this user's daemon runs. By default
          it is built from init.el plus custom.emacs.extraInit.
        '';
      };

      extraInit = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [ ];
        description = ''
          Extra elisp files appended to init.el. Each may contain
          use-package declarations, which are installed automatically.
          Modules such as emacs-extras.latex add themselves here.
        '';
      };

      extraEmacsPackages = lib.mkOption {
        type = lib.types.listOf (lib.types.functionTo (lib.types.listOf lib.types.package));
        default = [ ];
        description = ''
          Functions from the epkgs set to extra Emacs packages that
          aren't referenced via a use-package form, e.g. tree-sitter
          grammars. Modules such as emacs-extras.devel add themselves
          here.
        '';
      };
      

      daemon.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether to run Emacs as this user's systemd daemon. Disable
          it if you prefer to launch Emacs manually.
        '';
      };
    };

    config = {
      home.packages = [ config.custom.emacs.package ];

      services.emacs = {
        enable = config.custom.emacs.daemon.enable;
        package = config.custom.emacs.package;
        defaultEditor = true;
      };

      home.shellAliases = {
        e = "emacsclient -c -a ''";
        et = "emacsclient -nw -a ''";
      };
    };
  };

  perSystem = { pkgs, ... }: let
    emacsTheme = pkgs.writeText "theme.el" ''
      ;; -*- lexical-binding: t; -*-
      (defconst my/theme
        '(${pkgs.lib.concatStringsSep "\n    " (pkgs.lib.mapAttrsToList (name: value: "(${name} . \"${value}\")") self.theme)}))

      (defun my/c (name)
        "Colour NAME from theme.nix, as a hex string."
        (alist-get name my/theme))
    '';
  in {
    overlays = [ inputs.emacs-overlay.overlays.default ];

    packages.emacsTheme = emacsTheme;

    legacyPackages.mkEmacs = { extraInit, extraEmacsPackages ? [ ] }: pkgs.emacsWithPackagesFromUsePackage {      
      config = pkgs.runCommand "init.el" { } ''
        cat ${emacsTheme} ${./init.el} ${pkgs.lib.concatMapStringsSep " " (f: "${f}") extraInit} > $out
      '';
      defaultInitFile = true;
      package = pkgs.emacs-pgtk;
      alwaysEnsure = true;
      alwaysTangle = true;
      extraEmacsPackages = epkgs: builtins.concatMap (f: f epkgs) extraEmacsPackages;
    };
  };
}
