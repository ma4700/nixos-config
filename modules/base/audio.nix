{ self, inputs, ... }: {
  flake.nixosModules.audio = { ... }: {
    # Pipewire / wireplumber
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true; 
      wireplumber.enable = true;
    };

    services.pulseaudio.enable = false;
  };
}
