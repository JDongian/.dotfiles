# Bootable installer ISO for obsidian (ThinkPad X1 Carbon 7th gen).
#
# WHAT MAKES THIS DIFFERENT FROM A STOCK NixOS ISO:
#   1. This repo is embedded at /etc/nixos on the live image, so the install
#      needs no `git clone` and no network to fetch the config.
#   2. The full store closure of the obsidian system is embedded too, so
#      `nixos-install` runs entirely OFFLINE and installs exactly the revision
#      that was tested here -- not whatever master happens to be that day.
#   3. Saved Wi-Fi profiles are baked in (see wifiProfiles below).
#
# SECURITY: item 3 means THIS ISO, AND ANY USB WRITTEN FROM IT, CONTAINS
# PLAINTEXT Wi-Fi PASSWORDS. Treat the USB as a secret-bearing object: anyone
# holding it can read every saved PSK. The profiles come from the gitignored
# wifi-secrets/ directory, so they are never committed to this public repo.
{ config, pkgs, lib, modulesPath, obsidianSystem, repoSrc, wifiDir ? null, ... }:

let
  # WHY wifiDir IS PASSED IN RATHER THAN READ FROM repoSrc:
  # repoSrc is the flake's `self`, and for a git flake `self` contains ONLY
  # GIT-TRACKED FILES. wifi-secrets/ is deliberately gitignored (it holds
  # plaintext PSKs and this repo is public), so it is INVISIBLE inside `self`
  # -- reading repoSrc + "/wifi-secrets" silently yields nothing, producing an
  # ISO with zero Wi-Fi profiles and no error. Verified: the first version of
  # this file did exactly that.
  #
  # So the directory is passed as an absolute path from outside the flake,
  # which also keeps secrets out of the public flake source entirely. It is
  # copied to the store at build time (an impure-ish path read), which is
  # fine here: this ISO is a local artifact, never a shared build product.
  haveWifi = wifiDir != null && builtins.pathExists wifiDir;
in
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  isoImage.isoName = lib.mkForce "nixos-obsidian-installer.iso";
  isoImage.volumeID = lib.mkForce "OBSIDIAN_INST";

  # Compress hard: the embedded closure is the bulk of the image and the
  # target USB is only 14.6 GB.
  isoImage.squashfsCompression = "zstd -Xcompression-level 15";

  # --- The offline payload ---------------------------------------------------
  # Putting the toplevel in the ISO's store makes `nixos-install --system`
  # a pure copy: no substituters, no network, no surprise version drift.
  isoImage.storeContents = [ obsidianSystem ];

  # The repo itself, so /etc/nixos on the INSTALLED machine is a real checkout
  # and `nixos-rebuild` works immediately after first boot.
  isoImage.contents = [
    {
      source = repoSrc;
      target = "/etc/nixos-repo";
    }
  ];

  # --- Live environment ------------------------------------------------------
  environment.systemPackages = with pkgs; [
    git
    vim
    parted
    cryptsetup
    gptfdisk
  ];

  # Wireless on the live ISO, so you can get online mid-install if you want to
  # (the install itself does not need it).
  networking.networkmanager.enable = true;
  networking.wireless.enable = lib.mkForce false; # NM owns the radio

  # /etc contents for the LIVE system: the install script, plus the saved
  # Wi-Fi profiles so the installer environment itself auto-connects to known
  # networks. Both go through one environment.etc definition — Nix rejects the
  # attribute being defined twice in a single attrset.
  environment.etc = {
    # Convenience: a fixed path to run the installer from.
    "install-obsidian.sh" = {
      source = repoSrc + "/scripts/install-obsidian.sh";
      mode = "0755";
    };
  } // lib.optionalAttrs haveWifi (
    lib.listToAttrs (
      map
        (name: {
          name = "NetworkManager/system-connections/${name}";
          value = {
            source = wifiDir + "/${name}";
            # 0600 is mandatory — NetworkManager silently ignores any
            # connection file readable by group or other.
            mode = "0600";
          };
        })
        (builtins.attrNames (lib.filterAttrs (n: t: t == "regular")
          (builtins.readDir wifiDir)))
    )
  );

  services.getty.helpLine = lib.mkForce ''

    ╭──────────────────────────────────────────────────────────────╮
    │  obsidian installer — ThinkPad X1 Carbon 7th gen             │
    │                                                              │
    │  Run:  sudo /etc/install-obsidian.sh                         │
    │                                                              │
    │  WIPES /dev/nvme0n1 and installs NixOS offline.              │
    │  You will be asked to set the LUKS passphrase.               │
    ╰──────────────────────────────────────────────────────────────╯
  '';

  # The live ISO user needs no password.
  users.users.root.initialHashedPassword = lib.mkForce "";
}
