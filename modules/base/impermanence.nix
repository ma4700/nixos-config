{ self, inputs, ... }: {
  # The LUKS mapper name must be "cryptroot" and the sbuvolume names must match
  flake.nixosModules.impermanence = { pkgs, ... }: {
    imports = [ inputs.impermanence.nixosModules.impermanence ];

    # After LUKS is unlocked, before / is mounuted, replace the root
    # subvolume with a fresh empty one

    boot.initrd.systemd.enable = true;
    boot.initrd.systemd.initrdBin = [ pkgs.btrfs-progs ];
    boot.initrd.systemd.services.rollback = {
      description = "Reset btrfs root subvolume to empty";
      wantedBy = [ "initrd.target" ];
      after = [ "systemd-cryptsetup@cryptroot.service" ];
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = ''
        mkdir -p /mnt
      	mount -o subvol=/ /dev/mapper/cryptroot /mnt
      
      	# nested subvolumes must go first
      	btrfs subvolume list -o /mnt/root | cut -f9 -d' ' | while read -r subvolume; do
      	  btrfs subvolume delete "/mnt/$subvolume"
      	done
      	btrfs subvolume delete /mnt/root
      	btrfs subvolume create /mnt/root
      
      	umount /mnt
      '';
    };

    # /persist must be mounter in stage 1
    fileSystems."/persist".neededForBoot = true;

    environment.persistence."/persist" = {
      hideMounts = true;
      directories = [ "/var/lib/nixos" ]; # uid/gid maps
      files = [ "/etc/machine-id" ];
    };

    # machine-id is a bind mount, so systemd must not try to commit it
    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

    users.mutableUsers = false;

    security.sudo.extraConfig = ''
      Defaults lecture = never
    '';
  };
}







