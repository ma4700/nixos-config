{ self, inputs, ... }: {
  
 flake.nixosModules.bomberHardware = { config, lib, pkgs, modulesPath, ... }: {
    imports =
      [ (modulesPath + "/installer/scan/not-detected.nix")
      ];
  
    boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "sd_mod" ];
    boot.initrd.kernelModules = [ "amdgpu" "tcp_bbr" ];
    boot.kernelModules = [ "kvm-amd" ];
    boot.extraModulePackages = [ ];
  
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  }; 

}
