# Declarative disk layout for obsidian (ThinkPad X1 Carbon 7th gen).
#
# WHY THIS EXISTS SEPARATELY FROM disko.nix: disko.nix (gravel) has no swap
# partition and leaves the LUKS mapper auto-named. obsidian hibernates, which
# needs BOTH a swap partition sized >= RAM and a device path that is knowable
# BEFORE the disk exists so power.nix can be written statically.
#
# THE NAMING POINT (this is the whole reason this file is shaped this way):
# tile was installed BY HAND, so nothing ever assigned GPT partition names --
# `ls /dev/disk/by-partlabel/` on tile shows only EFI and root, with NO entry
# for its swap partition, and its LUKS mappers carry nixos-generate-config's
# auto `luks-<uuid>` names. by-uuid was therefore the only stable handle tile
# could possibly use; it was a consequence of the manual install, not a choice.
# disko assigns both the partlabel and the mapper name declaratively, so
# obsidian can reference /dev/mapper/cryptswap in a config written before the
# machine is ever partitioned. No post-install UUID patching.
#
# WHAT THIS DOES *NOT* FIX: the failure that actually broke tile's resume was
# systemd-initrd not unlocking LUKS before attempting resume. That bites
# by-uuid and by-partlabel identically -- naming is orthogonal to it. The
# defense is in power.nix: never set boot.initrd.systemd.enable.
{ device ? "/dev/nvme0n1", ... }:
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        inherit device;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              label = "ESP";
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "defaults" "umask=0077" ];
              };
            };

            # Encrypted swap. Sized 17G for a 16G-RAM X1C7: a hibernation
            # image can approach full RAM, and the kernel refuses to hibernate
            # into swap that cannot hold it ("Not enough suitable swap space").
            # Mirrors tile's 17757016 kB partition almost exactly.
            #
            # Declared BEFORE root so `size = "100%"` on root consumes only
            # what is left; disko allocates in declaration order.
            swap = {
              priority = 2;
              label = "swap";
              size = "17G";
              content = {
                type = "luks";
                # The name that makes this whole approach work: yields a
                # deterministic /dev/mapper/cryptswap. power.nix points
                # resumeDevice at exactly this path.
                name = "cryptswap";
                settings.allowDiscards = true;
                content = {
                  type = "swap";
                  # Hibernate target. Priority 0 (lowest) so ordinary paging
                  # fills the swapFILE first and leaves this partition empty
                  # for a hibernation image -- tile learned this the hard way
                  # on 2026-06-24 when an inverted priority let paging fill
                  # the partition and hibernate was refused outright.
                  priority = 0;
                  discardPolicy = "both";
                };
              };
            };

            root = {
              priority = 3;
              label = "root";
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                settings.allowDiscards = true;
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                  mountOptions = [ "defaults" "noatime" ];
                };
              };
            };
          };
        };
      };
    };
  };
}
