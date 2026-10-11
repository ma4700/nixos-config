{ self, inputs, ... }: {
  flake.nixosModules.audio = { pkgs, ... }: {
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

    # Small service to mute every mic on launch
    systemd.user.services.mute-mics = {
      wantedBy = [ "default.target" ];
      after = [ "pipewire.service" "wireplumber.service" ];
      path = with pkgs; [ pipewire wireplumber jq gnugrep ];
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = 3;
      };
      script = ''
        declare -A seen
        handle() {
          for id in $(pw-dump | jq -r '.[] | select(.type=="PipeWire:Interface:Node" and .info.props["media.class"]=="Audio/Source") | .id'); do
            if [ -z "''${seen[$id]:-}" ]; then
              seen[$id]=1
              wpctl set-mute "$id" 1
            fi
          done
        }
        { echo start; pw-mon | grep --line-buffered 'added:'; } \
          | while read -r _; do sleep 1; handle; done
      '';
    };    

    services.pulseaudio.enable = false;
  };
}
