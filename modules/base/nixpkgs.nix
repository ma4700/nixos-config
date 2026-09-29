{ inputs, lib, ... }: {
  perSystem = { system, config, lib, ... }: {
    options.overlays = lib.mkOption {
      type = lib.types.listOf lib.types.raw;
      default = [ ];
      description = ''
        Overlays to layer onto the shared `pkgs` for this system.
        Any module can append here like this:
        `perSystem = { ... }: { overlays = [ inputs.foo.overlays.default ]; };`
      '';
    };

    options.unfreePackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Package names to allow despite their unfree license.
        Any module can append here like this:
        `perSystem = { ... }: { unfreePackages = [ "discord" ]; };`
      '';
    };

    config._module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = config.overlays;
      config.allowUnfreePredicate =
        pkg: builtins.elem (lib.getName pkg) config.unfreePackages;
    };
  };
}
