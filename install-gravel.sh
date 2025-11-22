#!/usr/bin/env bash
set -euxo pipefail

sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
    --mode disko \
    --flake github:JDongian/.dotfiles#gravel

sudo nixos-generate-config --root /mnt --no-filesystems

sudo mkdir -p /mnt/etc/nixos/hosts/gravel
sudo mv /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/hosts/gravel/

cd /mnt/etc/nixos
sudo git clone https://github.com/JDongian/.dotfiles.git .

sudo nixos-install --root /mnt --flake .#gravel --no-root-password
