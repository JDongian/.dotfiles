{ config, pkgs, lib, ... }:

{
  # ThinkPad T490s specific hardware configuration
  # For a new laptop, copy this file and update the hardware-specific values below

  # Hostname for this machine
  networking.hostName = "tile";

  # Fix ThinkPad T490s audio volume issues
  boot.kernelParams = [ "snd_hda_intel.dmic_detect=0" ];

  # Optional: may help with mute LED keys
  boot.extraModprobeConfig = ''
    options snd-hda-intel model=auto
  '';

  # Enable disk encryption with LUKS
  # This UUID is specific to this machine's encrypted partition
  boot.initrd.luks.devices."luks-d2e857c5-e64e-4ec9-ad84-9794dea3ebf2".device = "/dev/disk/by-uuid/d2e857c5-e64e-4ec9-ad84-9794dea3ebf2";

  # Enable fingerprint reader (ThinkPad T490s has fprintd-compatible reader)
  services.fprintd.enable = true;

  # NOTE: Home Manager hardware-specific settings for this laptop:
  # - Hyprland monitor: monitor=eDP-1,1920x1080@60.01,0x0,1.0
  # - Waybar backlight device: "intel_backlight"
  # - Waybar IOPS disk: /^sda/
  # These need to be configured in the host-specific home.nix or passed via specialArgs
}
