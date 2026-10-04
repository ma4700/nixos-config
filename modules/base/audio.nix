{ self, inputs, ... }: {
  flake.nixosModules.audio = { ... }: {
    # Pipewire / wireplumber
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true; 
      wireplumber = {
        enable = true;
        extraConfig."10-bluez"."monitor.bluez.properties"."bluez5.auto-connect" = [ ];
      };
    };

    services.pulseaudio.enable = false;
  };
}
