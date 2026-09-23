# Bootable installer ISO for obsidian (ThinkPad X1 Carbon 7th gen).
#
# WHAT MAKES THIS DIFFERENT FROM A STOCK NixOS ISO:
#   1. This repo is embedded at /etc/nixos on the live image, so the install
#      needs no `git clone` and no network to fetch the config.
#   2. Package REVISIONS are pinned by the embedded flake.lock, so the install
#      matches what was verified here rather than whatever master is that day.
#      The packages themselves come from cache.nixos.org -- embedding the full
#      closure was tried and abandoned (39.3 GiB closure -> 15.31 GiB ISO vs a
#      14.65 GiB stick). See the payload note below.
#   3. Saved Wi-Fi profiles are baked in (see wifiProfiles below).
#
# SECURITY: item 3 means THIS ISO, AND ANY USB WRITTEN FROM IT, CONTAINS
# PLAINTEXT Wi-Fi PASSWORDS. Treat the USB as a secret-bearing object: anyone
# holding it can read every saved PSK. The profiles come from the gitignored
# wifi-secrets/ directory, so they are never committed to this public repo.
# obsidianSystem is accepted but currently unused -- see the payload note
# below. Kept in the signature so re-enabling the offline closure is a
# one-line change rather than a flake edit too.
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

  # Dvorak on the live installer console too, matching the installed system.
  console.keyMap = lib.mkForce "dvorak";

  isoImage.isoName = lib.mkForce "nixos-obsidian-installer.iso";
  isoImage.volumeID = lib.mkForce "OBSIDIAN_INST";

  # Default compression is fine now that the big closure is gone; -15 only
  # cost build time.
  isoImage.squashfsCompression = "zstd -Xcompression-level 6";

  # --- Payload ---------------------------------------------------------------
  # NOT embedding the obsidian system closure. It was tried (2026-09-22) and
  # the resulting ISO came to 15.31 GiB against a 14.65 GiB stick -- the full
  # desktop closure (hyprland, texlive, ...) simply does not fit. Check
  # `nix path-info -Sh .#nixosConfigurations.obsidian.config.system.build.toplevel`
  # before considering it again; it needs a >=32 GB USB.
  #
  # Consequence: the install is NOT air-gapped -- nixos-install pulls from
  # cache.nixos.org. That is fine because the Wi-Fi profiles below are baked
  # in, so the X1 associates with a known network on boot and the install
  # proceeds unattended. flake.lock is in the embedded repo, so the installed
  # system is still pinned to the exact revision verified here; only the
  # DELIVERY of those paths is over the network, not their identity.
  # isoImage.storeContents = [ obsidianSystem ];

  # The repo itself, so /etc/nixos on the INSTALLED machine is a real checkout
  # and `nixos-rebuild` works immediately after first boot.
  isoImage.contents = [
    {
      source = repoSrc;
      target = "/etc/nixos-repo";
    }
  ];

  # --- Live environment ------------------------------------------------------
  # Intel wifi firmware. The X1C7 has an AX200/9560 needing iwlwifi blobs;
  # the minimal installation-cd profile does not guarantee them.
  hardware.enableRedistributableFirmware = true;

  environment.systemPackages = with pkgs; [
    git
    vim
    parted
    cryptsetup
    gptfdisk
    curl # install-obsidian.sh probes cache.nixos.org with it
    wpa_supplicant # CLI fallback if NetworkManager will not drive the radio
    iw # `iw dev <if> scan` to prove the radio works independently of NM
  ];

  # Wireless on the live ISO, so you can get online mid-install if you want to
  # (the install itself does not need it).
  # NetworkManager owns the radio. Do NOT add
  # `networking.wireless.enable = lib.mkForce false` here: that removes
  # wpa_supplicant ENTIRELY (package and D-Bus service), and NM drives wifi
  # THROUGH wpa_supplicant. The result on the X1 (2026-09-22) was a wifi
  # device stuck at "unavailable" with nothing rfkill-blocked and the
  # firmware loaded fine -- NM logged "failed to D-Bus activate wpa" and
  # parked the interface. The installation-cd profile already leaves
  # wireless.enable off by default, so NM's own wpa_supplicant dependency is
  # all that is needed; forcing it false is what broke it.
  networking.networkmanager.enable = true;

  # networking.wireless.enable is deliberately NOT set here. Enabling
  # NetworkManager already sets it to true (see nixos/modules/services/
  # networking/networkmanager.nix), which is what puts wpa_supplicant and its
  # D-Bus service on the image. Setting it false -- even with mkForce -- takes
  # wpa_supplicant away and leaves NM unable to drive the radio at all.

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
    │  WIPES /dev/nvme0n1 and installs NixOS.                      │
    │  You will be asked to set the LUKS passphrase.               │
    │                                                              │
    │  Needs network — saved Wi-Fi should connect automatically.   │
    │  Check with:  nmcli device wifi list                         │
    ╰──────────────────────────────────────────────────────────────╯
  '';

  # The live ISO user needs no password.
  users.users.root.initialHashedPassword = lib.mkForce "";
}
