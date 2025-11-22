#!/usr/bin/env bash
set -euxo pipefail

# Download disko configuration locally (disko requires local file, not URL)
curl -fsSL https://raw.githubusercontent.com/JDongian/.dotfiles/master/disko.nix -o /tmp/disko.nix

# Run disko to partition and encrypt the disk
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
    --mode disko \
    /tmp/disko.nix

# Generate hardware config WITHOUT filesystem declarations (--no-filesystems flag)
# This avoids conflicts with disko's filesystem management
sudo nixos-generate-config --root /mnt --no-filesystems

# Organize hardware config into hosts/gravel directory
sudo mkdir -p /mnt/etc/nixos/hosts/gravel
sudo mv /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/hosts/gravel/

# Clone dotfiles repository into /mnt/etc/nixos
cd /mnt/etc/nixos
sudo git clone https://github.com/JDongian/.dotfiles.git .

# Install NixOS with the gravel flake configuration
sudo nixos-install --root /mnt --flake .#gravel --no-root-password

# Fix user setup: remove password lock so joshua can log in
# (User can set password after first login)
sudo nixos-enter --root /mnt -c "passwd -d joshua"
