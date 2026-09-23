{ config, pkgs, lib, ... }:

{
  imports = [
    # Main shared system configuration (same one tile uses)
    ../../configuration.nix

    # Declarative disk layout: LUKS root + LUKS swap with STABLE mapper names.
    # Replaces the hand-rolled hardware-configuration.nix filesystem block --
    # disko owns fileSystems and swapDevices for the encrypted volumes.
    ../../disko-obsidian.nix

    # X1 Carbon 7th gen specific tweaks
    ./hardware.nix

    # All power management (suspend/hibernate/lid/resume/charge), ported from
    # tile with obsidian's stable device paths substituted.
    ./power.nix
  ];
}
