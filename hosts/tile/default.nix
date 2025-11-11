{ config, pkgs, lib, ... }:

{
  imports = [
    # Main shared system configuration
    ../../configuration.nix

    # Hardware-specific auto-generated configuration
    ./hardware-configuration.nix

    # ThinkPad T490s specific tweaks and settings
    ./hardware.nix
  ];
}
