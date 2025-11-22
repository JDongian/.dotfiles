#!/usr/bin/env bash
#
# Automated NixOS installation script for gravel (X1 Carbon)
#
# Usage: Place this script in /mnt/etc/nixos/ with your configs, then run:
#   sudo /mnt/etc/nixos/install-gravel.sh
#
# WARNING: This will DESTROY ALL DATA on /dev/nvme0n1
#

set -euo pipefail

# Configuration
DISK="/dev/nvme0n1"
HOSTNAME="gravel"
CONFIG_SOURCE="$(cd "$(dirname "$0")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Pre-flight checks
check_root() {
    [[ $EUID -eq 0 ]] || { log_error "Must run as root: sudo $0"; exit 1; }
}

check_disk() {
    [[ -b "$DISK" ]] || { log_error "Disk $DISK not found"; lsblk -d; exit 1; }
    log_info "Found disk: $DISK"
}

check_network() {
    ping -c 1 1.1.1.1 &>/dev/null || { log_error "No network. Use nmtui to connect."; exit 1; }
    log_success "Network OK"
}

check_config() {
    [[ -f "$CONFIG_SOURCE/flake.nix" ]] || { log_error "flake.nix not found in $CONFIG_SOURCE"; exit 1; }
    [[ -f "$CONFIG_SOURCE/disko.nix" ]] || { log_error "disko.nix not found in $CONFIG_SOURCE"; exit 1; }
    log_success "Config found at $CONFIG_SOURCE"
}

confirm_installation() {
    echo ""
    log_warn "⚠️  WARNING: This will DESTROY ALL DATA on $DISK"
    echo ""
    echo "This will:"
    echo "  1. Wipe $DISK"
    echo "  2. Create LUKS encrypted partitions"
    echo "  3. Install NixOS as '$HOSTNAME'"
    echo ""

    read -p "Type 'yes' to continue: " confirm
    [[ "$confirm" == "yes" ]] || { log_info "Cancelled"; exit 0; }

    read -p "Type hostname to confirm: " hostname_confirm
    [[ "$hostname_confirm" == "$HOSTNAME" ]] || { log_error "Hostname mismatch"; exit 1; }
}

partition_disk() {
    log_info "Partitioning $DISK with disko (you'll be prompted for LUKS passphrase)..."

    # Clean up any existing mounts
    mountpoint -q /mnt && umount -R /mnt 2>/dev/null || true
    [[ -e /dev/mapper/cryptroot ]] && cryptsetup close cryptroot 2>/dev/null || true

    # Run disko
    nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
        --mode disko \
        "$CONFIG_SOURCE/disko.nix" \
        --arg device "\"$DISK\""

    log_success "Disk partitioned and mounted at /mnt"
}

copy_config() {
    log_info "Copying configuration to /mnt/etc/nixos..."
    mkdir -p /mnt/etc/nixos
    cp -r "$CONFIG_SOURCE"/* /mnt/etc/nixos/
    log_success "Configuration copied"
}

generate_hardware_config() {
    log_info "Generating hardware configuration..."

    nixos-generate-config --root /mnt --no-filesystems

    # Move to gravel host directory
    mkdir -p /mnt/etc/nixos/hosts/$HOSTNAME
    mv /mnt/etc/nixos/hardware-configuration.nix \
       /mnt/etc/nixos/hosts/$HOSTNAME/hardware-configuration.nix

    log_success "Hardware config generated"
}

install_system() {
    log_info "Installing NixOS (this takes 15-30 minutes)..."
    echo ""

    nixos-install \
        --root /mnt \
        --flake "/mnt/etc/nixos#$HOSTNAME" \
        --no-root-password

    log_success "NixOS installed"
}

final_message() {
    echo ""
    log_success "╔════════════════════════════════════════════════════════════╗"
    log_success "║          Installation Complete! 🎉                         ║"
    log_success "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Next steps:"
    echo "  1. sudo reboot"
    echo "  2. Remove USB drive"
    echo "  3. Enter LUKS passphrase at boot"
    echo "  4. Log in as 'joshua'"
    echo "  5. Set password: passwd"
    echo ""
    echo "To configure hibernation later, see /etc/nixos/hosts/gravel/hardware.nix"
    echo ""
}

main() {
    echo ""
    log_info "NixOS Installation for $HOSTNAME"
    echo ""

    # Checks
    check_root
    check_disk
    check_network
    check_config
    log_success "Pre-flight checks passed"

    # Confirm
    confirm_installation

    # Install
    partition_disk
    copy_config
    generate_hardware_config
    install_system

    # Done
    final_message
}

main "$@"
