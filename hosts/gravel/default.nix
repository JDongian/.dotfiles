{ config, pkgs, lib, ... }:

{
  imports = [
    # Main shared system configuration
    ../../configuration.nix

    # Disko declarative disk partitioning
    ../../disko.nix

    # Hardware detection (generated during install)
    ./hardware-configuration.nix

    # X1 Carbon specific tweaks and settings
    ./hardware.nix
  ];
}
