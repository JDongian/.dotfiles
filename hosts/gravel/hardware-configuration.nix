{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "usb_storage"
    "sd_mod"
    "sdhci_pci"
  ];

  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Root filesystem (ext4 inside LUKS)
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/424952a0-0183-4950-ace9-574deeb079f4";
    fsType = "ext4";
  };

  # LUKS device for root
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/14a28eec-6e5a-464f-8717-390a7436662e";
    allowDiscards = true;
  };

  # EFI boot
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/929A-D700";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ]; # you are using a swapfile in configuration.nix

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

