{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Set hostname for this machine
  networking.hostName = "gravel";

  # X1 Carbon 6th gen and later typically use Intel CPUs
  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Enable Intel CPU microcode updates
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # X1 Carbon specific hardware features
  services.fprintd.enable = true; # Fingerprint reader support

  # Enable TLP for better battery management
  services.tlp = {
    enable = true;
    settings = {
      # Optimize for battery life
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      
      # ThinkPad battery thresholds
      START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };

  # Enable thermald for Intel thermal management
  services.thermald.enable = true;

  # X1 Carbon typically has good hardware support for most features
  hardware.enableRedistributableFirmware = true;

  # Platform identification
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
