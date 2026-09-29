{self, inputs, lib, ... }: {
  options.flake.homeManagerModules = lib.mkOption {
    # a value is either a module or a group of modules (e.g. emacs-extras.latex)
    type = lib.types.lazyAttrsOf (lib.types.either
      (lib.types.lazyAttrsOf lib.types.deferredModule)
      lib.types.deferredModule);    
    default = { };
    description = ''
      Home-manager modules self-registered teh same way as
      flake.nixosModules
      '';
  };

  config.flake.nixosModules.home-manager = { ... }: {
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm-backup";
    };
  };
}
