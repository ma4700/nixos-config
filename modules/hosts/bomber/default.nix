{ self, inputs, ... }: {

  flake.nixosConfigurations.bomber = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.bomberConfiguration
     ];
  };

}
