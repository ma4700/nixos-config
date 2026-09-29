{ self, inputs, ... }: {
  
  flake.nixosModules.bomberConfiguration = { pkgs, lib, ... }: {
    imports =
      [ # Include the results of the hardware scan.
        self.nixosModules.bomberHardware
      	self.nixosModules.bomberDisko
      	self.nixosModules.impermanence
        self.nixosModules.niri
        self.nixosModules.kitty
        self.nixosModules.keyd
        self.nixosModules.home-manager
        self.nixosModules.bomberUsers
        self.nixosModules.hyprland
        self.nixosModules.nmtui-theme
        self.nixosModules.grub-theme
        self.nixosModules.audio
      ] ++ lib.optional self.bluetoothEnabled self.nixosModules.bluetooth ++ [
      ];

    # Enable flakes
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # Use grub
    boot.loader.grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      copyKernels = true;
      configurationLimit = 10;
    };
    boot.loader.efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };

    # --- Battery saving ---
    # Using p-state driver for better battery life / perf scaling
    # Forcing deep sleep (S3) for less battery drain
    # NVME drive, deeper power state
    # Lower power states for idle PCIE links between bursts
    # ----------------------
    boot.kernelParams = [ "amd_pstate=active" "mem_sleep_default=deep" "nvme_core.default_ps_max_latency_us=5500" "pcie_aspm=force" "systemd.show_status=error" ];
    # --- Wifi optimization ---
    # Disable deep power saving for the rtw88 driver - less laggy/dropping wifi
    # Enable MSI interrupts for lower latency
    # -------------------------
    boot.extraModprobeConfig = ''
      options rtw88_core disable_lps_deep=1
      options rtw88_pci disable_msi=0
    '';
    # --- Wifi optimization ---
    # Lowe latency, better throughput
    # -------------------------
    boot.kernel.sysctl =  {
      "net.ipv4.tcp_congestion_protocol" =  "bbr";
      "net.core.default_qdisc" = "fq";
      
      # Bigger buffer helps wireguard push more
      # throughput without stalling on bufferbloat
      "net.core.rmem_max" = 26214400;
      "net.core.wmem_max" = 26214400;
      "net.core.rmem_default" = 1048576;
      "net.core.wmem_default" = 1048576;
      "net.ipv4.tcp_rmem" = "4096 1048576 26214400";
      "net.ipv4.tcp_wmem" = "4096 1048576 26214400";
      
      # Reduces latency spikes under load - makes RDP more responsive
      "net.ipv4.tcp_notsent_lowat" = 16384;
    };
  
    # Use latest kernel.
    boot.kernelPackages = pkgs.linuxPackages_latest;
  
    networking.hostName = "bomber"; # Define your hostname.
  
    # Configure network connections interactively with nmcli or nmtui.
    networking.networkmanager = {
      enable = true;
      wifi.powersave = false;
      wifi.backend = "iwd";
    };

    # Set your time zone.
    time.timeZone = "Europe/Athens";
  
    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  
    # Select internationalisation properties.
    # i18n.defaultLocale = "en_US.UTF-8";
    # console = {
    #   font = "Lat2-Terminus16";
    #   keyMap = "us";
    #   useXkbConfig = true; # use xkb.options in tty.
    # };

    # Graphics
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          libva
          mesa
        ];
      };
      amdgpu = {
        opencl.enable = true;
        # initrd.enable = true;
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
  
    # Enable the X11 windowing system.
    # services.xserver.enable = true;
  
    # Configure keymap in X11
    # services.xserver.xkb.layout = "us";
    # services.xserver.xkb.options = "eurosign:e,caps:escape";
  
    # Enable CUPS to print documents.
    # services.printing.enable = true;
  
    # Enable sound.
    # services.pulseaudio.enable = true;
    # OR
    # services.pipewire = {
    #   enable = true;
    #   pulse.enable = true;
    # };
  
    # Enable touchpad support (enabled default in most desktopManager).
    services.libinput.enable = true;
  
    # programs.firefox.enable = true;
  
    # List packages installed in system profile.
    # You can use https://search.nixos.org/ to find more packages (and options).

    # Enable unfree packages
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
        "corefonts"
        "vista-fonts"
	"osu-lazer-bin"
        "discord"
	"discord-unwrapped"
      ];

    environment.systemPackages = with pkgs; [
      vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
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
      radeontop
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

    # Console font and colours
    console = {
      packages = [ pkgs.terminus_font ];
      font = "ter-v20n";
    };    
  
    # Some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    # programs.mtr.enable = true;
    # programs.gnupg.agent = {
    #   enable = true;
    #   enableSSHSupport = true;
    # };
  
    # List services that you want to enable:
  
    # Lets desktop shell switch power profiles
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

    # Enable upower daemon
    services.upower.enable = true;

    # Allow a user to poweroff/reboot while another user has a session running
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if ((action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
             action.id == "org.freedesktop.login1.reboot-multiple-sessions") &&
            subject.isInGroup("users")) {
          return polkit.Result.YES;
        }
      });
    '';

    # Hide login banner on TTY << Welcome to NixOS ... >>
    services.getty = {
      greetingLine = lib.mkForce "[ \\l ]";
      helpLine = lib.mkForce "";
      extraArgs = [ "--nohostname" ];
    };    

    # PlatformIO board flashing without sudo
    services.udev.packages = [ pkgs.platformio-core.udev ];

    # Belt-and-suspenders udev rule for killing wifi power management in case the modprobe option stops working
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="net", KERNEL=="wl*", RUN+="${pkgs.iw}/bin/iw dev $env{INTERFACE} set power_save off"
    '';

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

    # Open ports in the firewall.
    # networking.firewall.allowedTCPPorts = [ ... ];
    # networking.firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    # networking.firewall.enable = false;
  
    # Copy the NixOS configuration file and link it from the resulting system
    # (/run/current-system/configuration.nix). This is useful in case you
    # accidentally delete configuration.nix.
    # system.copySystemConfiguration = true;
  
    # This option defines the first version of NixOS you have installed on this particular machine,
    # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
    #
    # Most users should NEVER change this value after the initial install, for any reason,
    # even if you've upgraded your system to a new NixOS release.
    #
    # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
    # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
    # to actually do that.
    #
    # This value being lower than the current NixOS release does NOT mean your system is
    # out of date, out of support, or vulnerable.
    #
    # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
    # and migrated your data accordingly.
    #
    # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
    system.stateVersion = "26.05"; # Did you read the comment?
  };

}
