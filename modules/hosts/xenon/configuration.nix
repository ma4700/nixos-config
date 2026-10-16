{ self, inputs, ... }: {

  flake.nixosModules.xenonConfiguration = { pkgs, lib, ... }: {
    imports =
      [
        self.nixosModules.xenonHardware
        self.nixosModules.xenonDisko
        self.nixosModules.impermanence
        self.nixosModules.niri
        self.nixosModules.kitty
        self.nixosModules.keyd
        self.nixosModules.home-manager
        self.nixosModules.xenonUsers
        self.nixosModules.hyprland
        self.nixosModules.nmtui-theme
        self.nixosModules.audio
      ] ++ lib.optional self.bluetoothEnabled self.nixosModules.bluetooth;

    # Enable flakes
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # Use grub, on its own ESP
    boot.loader.grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      copyKernels = true;
      splashImage = ./grub-background.jpg
      configurationLimit = 10;
      extraEntries = ''
        menuentry "Windows" {
          insmod part_gpt
          insmod fat
          insmod chain
          search --no-floppy --file --set=root /EFI/Microsoft/Boot/bootmgfw.efi
          chainloader /EFI/Microsoft/Boot/bootmgfw.efi
        }
      '';
    };
    boot.loader.efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };

    # Default kernel, not linuxPackages_latest, because the NVIDIA modules lag behind it

    boot.kernel.sysctl = {
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.core.default_qdisc" = "fq";

      "net.core.rmem_max" = 26214400;
      "net.core.wmem_max" = 26214400;
      "net.core.rmem_default" = 1048576;
      "net.core.wmem_default" = 1048576;
      "net.ipv4.tcp_rmem" = "4096 1048576 26214400";
      "net.ipv4.tcp_wmem" = "4096 1048576 26214400";

      # Reduces latency spikes under load
      "net.ipv4.tcp_notsent_lowat" = 16384;
    };

    networking.hostName = "xenon";

    networking.networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };

    time.timeZone = "Europe/Athens";
    # Windows keeps the hardware clock in local time
    time.hardwareClockInLocalTime = true;



    # Uses Intel iGPU. To run Nvidia use `nvidia-offload <app>`
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver # VA-API
      ];
    };

    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia = {
      open = true;
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = true;
      prime = {
        offload.enable = true;
        offload.enableOffloadCmd = true;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };

    # Force apps to render natively on wayland
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1"; # Chromium/Electron apps
      MOZ_ENABLE_WAYLAND = "1"; # Firefox
      QT_QPA_PLATFORM = "wayland"; # Qt apps
      _JAVA_AWT_WM_NONREPARENTING = "1"; # Fixes some Java/Swing apps
    };

    qt.enable = true;

    # Hyprland, correct scaling
    home-manager.sharedModules = [{
      wayland.windowManager.hyprland.settings.monitor = [ "eDP-1,preferred,auto,auto" ];
    }];
    
    # Enable touchpad support
    services.libinput.enable = true;

    # Enable unfree packages
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "corefonts"
      "vista-fonts"
      "osu-lazer-bin"
      "discord"
      "discord-unwrapped"
      "nvidia-x11"
      "nvidia-settings"
    ];

    environment.systemPackages = with pkgs; [
      vim
      wget
      git
      busybox
      tailscale
      freerdp
      keepassxc
      remmina
      firefox
      xwayland-satellite
      upower
      fastfetch
      wl-clipboard
      btop
      nvtopPackages.full
      moonlight-qt
      mullvad
      mullvad-vpn
      mullvad-browser
      lynis
      v4l-utils
      mpv
      libnotify
      strace
      alsa-utils
    ];

    # Install fonts
    fonts.packages = with pkgs; [
      corefonts
      vista-fonts
      jetbrains-mono
      nerd-fonts.jetbrains-mono
    ];

    fonts.fontconfig.enable = true;

    console = {
      packages = [ pkgs.terminus_font ];
      font = "ter-v24n";
    };

    services.power-profiles-daemon.enable = true;

    # Enable the OpenSSH daemon.
    services.openssh = {
      enable = true;
      hostKeys = [
        { path = "/persist/etc/ssh/ssh_host_ed25519_key"; type="ed25519"; }
        { path = "/persist/etc/ssh/ssh_host_rsa_key"; type="rsa"; bits=4096; }
      ];
    };

    # Enable tailscale
    services.tailscale = {
      enable = true;
      openFirewall = true; # Opens UDP 41641 for direct connections, if closed everything is relayed through tailscale's DERP servers
      useRoutingFeatures = "client";
    };

    # Mullvad
    services.mullvad-vpn.enable = true;

    # Enable upower daemon
    services.upower.enable = true;

    # Hide login banner on TTY << Welcome to NixOS ... >>
    services.getty = {
      greetingLine = lib.mkForce "[ \\l ]";
      helpLine = lib.mkForce "";
      extraArgs = [ "--nohostname" ];
    };

    # PlatformIO board flashing without sudo
    services.udev.packages = [ pkgs.platformio-core.udev ];

    services.journald.settings.Journal = {
      Storage = "persistent";
      SystemMaxUse = "200M";
      MaxRetentionSec = "2week";
    };

    # Persisted system state
    environment.persistence."/persist".directories = [
      "/var/log"
      "/var/lib/systemd/coredump"
      "/var/lib/iwd"
      "/etc/NetworkManager/system-connections"
      "/var/lib/tailscale"
      { directory = "/var/lib/bluetooth"; mode = "0700"; } # pairing keys
    ];

    # Did you read the comment?
    system.stateVersion = "26.11";
  };

}
