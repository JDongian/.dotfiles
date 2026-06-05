{ config, pkgs, lib, ... }:

{
  imports = [
    # Main shared system configuration
    ../../configuration.nix

    # Hardware-specific auto-generated configuration
    ./hardware-configuration.nix

    # ThinkPad T490s specific tweaks and settings
    ./hardware.nix

    # All power management (suspend/hibernate/lid/resume/charge). Central
    # module — the only power knob that lives elsewhere is the per-session
    # idle ladder in dotfiles/hypr/hypridle.conf (a home-manager dotfile).
    ./power.nix
  ];
}
