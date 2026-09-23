{ config, lib, pkgs, modulesPath, ... }:

# ThinkPad X1 Carbon 7th gen (20QD/20QE, Whiskey Lake i5/i7-8565U/8665U).
#
# Unlike tile, obsidian has NO generated hardware-configuration.nix: disko
# declares every filesystem, and the module list below covers the hardware.
# nixos-generate-config is therefore not run during install, which is what
# keeps the whole config static and knowable before the machine is touched.
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  networking.hostName = "obsidian";

  # X1C7 is NVMe + Thunderbolt 3. `thunderbolt` in initrd matters because the
  # TB3 ports can host boot-relevant devices; `nvme` is the internal disk.
  boot.initrd.availableKernelModules = [
    "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" "sdhci_pci"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Audio: the X1C7 uses the same Intel HDA + digital-mic arrangement that
  # made tile's volume keys misbehave, and carries a second quirk of its own.
  #
  # dmic_detect=0 (same as tile): stops snd-hda-intel handing the DMIC off to
  # the SOF driver, which on these Whiskey Lake ThinkPads leaves the speakers
  # mute and the volume keys inert.
  boot.kernelParams = [ "snd_hda_intel.dmic_detect=0" ];

  boot.extraModprobeConfig = ''
    options snd-hda-intel model=auto
  '';

  # Fingerprint reader. X1C7 ships a Synaptics sensor -- the same 06cb vendor
  # family as tile's, so the fprintd handling in power.nix applies directly.
  # NOTE: the exact product id can differ per unit; power.nix's udev rule
  # covers the common X1C7 ids alongside tile's. Verify with `lsusb` on first
  # boot and narrow the rule if you want it tight.
  services.fprintd.enable = true;

  # Dvorak. Note this DIFFERS from tile (QWERTY) -- set here rather than in
  # the shared configuration.nix so tile is unaffected. console.keyMap covers
  # the TTYs; the Wayland/Hyprland layout is separate and lives in the
  # hyprland input block, so set XKB here for anything that reads it.
  console.keyMap = "dvorak";
  services.xserver.xkb.layout = "dvorak";

  # Intel thermal management. tile's power.nix flags thermald/TLP as a
  # deferred TODO; obsidian takes them from the start (gravel already did).
  services.thermald.enable = true;

  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # ThinkPad charge thresholds: stop at 80% to preserve battery health.
      START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
