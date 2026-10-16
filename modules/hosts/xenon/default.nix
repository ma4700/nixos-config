{ self, inputs, ... }: {

  flake.nixosConfigurations.xenon = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.xenonConfiguration
    ];
  };

}
