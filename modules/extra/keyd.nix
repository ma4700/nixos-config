{ self, inputs, ... }: {
  flake.nixosModules.keyd = { pkgs, ... }: {
    services.keyd = {
      enable = true;
      keyboards.default = {
        ids = [ "*" ];
        settings.main = {
          capslock = "overload(control, capslock)";
        };
      };
    };

    # palm-rejection fix for keyd's virtual device, per upstream guidance
    environment.etc."libinput/local-overrides.quirks".text = ''
      [Keyd Virtual Keyboard]
      MatchUdevType=keyboard
      MatchName=keyd virtual keyboard
      AttrKeyboardIntegration=internal
    '';
  };
}
