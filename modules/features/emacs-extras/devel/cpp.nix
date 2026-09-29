{ self, inputs, ... }: {

  flake.homeManagerModules.emacs-extras.devel = { config, pkgs, lib, ... }: {
    config = {
      home.packages = with pkgs; [
        platformio
        gdb
        clang-tools
      ];

      custom.emacs.extraInit = [ ./cpp.el ];

      custom.emacs.extraEmacsPackages = [
        (epkgs: [
          (epkgs.treesit-grammars.with-grammars (g: [ g.tree-sitter-c g.tree-sitter-cpp ]))
        ])
      ];

      # PlatformIO's udev rules (pkgs.platformio-core.udev) go through
      # services.udev.packages on the host level.
    };
  };

}
