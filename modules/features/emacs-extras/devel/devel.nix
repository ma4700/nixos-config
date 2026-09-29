{ self, inputs, ... }: {

  flake.homeManagerModules.emacs-extras.devel = { config, pkgs, lib, ... }: {
    config = {
      home.packages = [ ];

      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };      

      custom.emacs.extraInit = [ ./devel.el ];
    };
  };

}
