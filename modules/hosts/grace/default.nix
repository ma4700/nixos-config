{ self, inputs, ... }: {

  flake.nixosConfigurations.grace = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.graceConfiguration
    ];
  };

}
