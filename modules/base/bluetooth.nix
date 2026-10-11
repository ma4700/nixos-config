{ self, inputs, ... }: {
  flake.bluetoothEnabled = true;

  flake.nixosModules.bluetooth = { pkgs, ... }: {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = false;
      settings.Policy.ReconnectAttempts = 0;
    };
  };
}
