{ self, inputs, ... }: {
  # Windows keeps the rest of the disk. install-xenon.sh creates the two
  # partitions below in the free space; disko only formats and mounts them.
  # (disko's gpt type numbers partitions from 1, which would hit Windows' ESP.)
  flake.nixosModules.xenonDisko = { ... }: {
    imports = [ inputs.disko.nixosModules.disko ];

    disko.devices.disk = {
      boot = {
        type = "disk";
        device = "/dev/disk/by-partlabel/xenon-boot";
        content = {
          type = "filesystem";
          format = "vfat";
          mountpoint = "/boot";
          mountOptions = [ "umask=0077" ];
        };
      };
      main = {
        type = "disk";
        device = "/dev/disk/by-partlabel/xenon-crypt";
        content = {
          type = "luks";
          name = "cryptroot"; # has to match the impermanence module
          settings.allowDiscards = true;
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "/root" = {
                mountpoint = "/";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
              "/nix" = {
                mountpoint = "/nix";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
              "/persist" = {
                mountpoint = "/persist";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
            };
          };
        };
      };
    };
  };
}
