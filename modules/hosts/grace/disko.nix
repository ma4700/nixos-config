{ self, inputs, ... }: {
  # The Windows partition on the HDD (and the SSD) stay. install-grace.sh removes
  # the old NixOS partitions and creates the two below in the freed space; disko
  # only formats and mounts them.
  # (disko's gpt type numbers partitions from 1, which would hit the Windows partition.)
  flake.nixosModules.graceDisko = { ... }: {
    imports = [ inputs.disko.nixosModules.disko ];

    disko.devices.disk = {
      boot = {
        type = "disk";
        device = "/dev/disk/by-partlabel/grace-boot";
        content = {
          type = "filesystem";
          format = "vfat";
          mountpoint = "/boot";
          mountOptions = [ "umask=0077" ];
        };
      };
      main = {
        type = "disk";
        device = "/dev/disk/by-partlabel/grace-crypt";
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
