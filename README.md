# NixOS Configuration

A declarative NixOS system configuration using flakes and home-manager.

![screenshot](screenshot.png)

## Features

### System Configuration
- Declarative configuration using [Nix flakes](https://nixos.wiki/wiki/Flakes) for full reproducibility
- Multi-host support with per-machine customization
- Automated hardware detection and configuration
- [Home-manager](https://github.com/nix-community/home-manager) integration for user-level package and dotfile management

### Desktop Environment
- [Hyprland](https://hyprland.org/) Wayland compositor with dynamic tiling
- [Waybar](https://github.com/Alexays/Waybar) status bar with custom styling
- [Fuzzel](https://codeberg.org/dnkl/fuzzel) application launcher
- [Foot](https://codeberg.org/dnkl/foot) terminal emulator
- [Hyprlock](https://github.com/hyprwm/hyprlock) screen locker

### Development Tools
- [Neovim](https://neovim.io/) with custom configuration
- [Tmux](https://github.com/tmux/tmux) terminal multiplexer
- [Starship](https://starship.rs/) cross-shell prompt
- Git with personalized settings
- Custom package overlays for bleeding-edge software

### Package Management
- Declarative package installation
- Custom overlays in `overlays/` directory
- Reproducible builds across machines
- Rollback capability for system configurations

## Installation and Running

### Prerequisites
- NixOS installed on your system
- Git for cloning the repository
- Flakes enabled in your Nix configuration

### Initial Setup

Clone the repository:
```bash
git clone git@github.com:JDongian/.dotfiles.git /etc/nixos
cd /etc/nixos
```

### Building the Configuration

For the default host:
```bash
sudo nixos-rebuild switch --flake .#tile
```

For other hosts (when added):
```bash
sudo nixos-rebuild switch --flake .#hostname
```

### Updating

Update flake inputs:
```bash
nix flake update
```

Rebuild after updating:
```bash
sudo nixos-rebuild switch --flake .#tile
```

## Structure

```
.
├── flake.nix                  # Flake configuration with inputs and outputs
├── flake.lock                 # Locked flake dependencies
├── configuration.nix          # Main system configuration
├── home.nix                   # Home-manager configuration for user joshua
├── hosts/                     # Host-specific configurations
│   └── tile/                  # ThinkPad T490s
│       ├── default.nix        # Host entry point
│       ├── hardware-configuration.nix  # Auto-generated hardware config
│       └── hardware.nix       # Hardware-specific tweaks
├── dotfiles/                  # Application dotfiles
│   ├── bashrc                 # Bash configuration
│   ├── foot/                  # Foot terminal config
│   ├── fuzzel/                # Fuzzel launcher config
│   ├── hypr/                  # Hyprland and Hyprlock config
│   ├── nvim/                  # Neovim configuration
│   ├── starship.toml          # Starship prompt config
│   ├── tmux/                  # Tmux configuration
│   └── waybar/                # Waybar config and styling
└── overlays/                  # Custom package overlays
    └── code-cursor-latest.nix # Code Cursor editor overlay
```

## Adding a New Host

1. Generate hardware configuration on the target machine:
   ```bash
   nixos-generate-config --show-hardware-config > /tmp/hardware-configuration.nix
   ```

2. Create host directory and files:
   ```bash
   mkdir -p hosts/hostname
   mv /tmp/hardware-configuration.nix hosts/hostname/
   ```

3. Create `hosts/hostname/default.nix`:
   ```nix
   { config, pkgs, lib, ... }:
   {
     imports = [
       ../../configuration.nix
       ./hardware-configuration.nix
       ./hardware.nix  # Optional: host-specific tweaks
     ];
   }
   ```

4. Add the new host to `flake.nix` outputs:
   ```nix
   nixosConfigurations.hostname = nixpkgs.lib.nixosSystem {
     specialArgs = { inherit inputs system; };
     modules = [
       ./hosts/hostname
       inputs.home-manager.nixosModules.default
       # ... rest of modules
     ];
   };
   ```

5. Build and switch:
   ```bash
   sudo nixos-rebuild switch --flake .#hostname
   ```

## Documentation

See the [NixOS Manual](https://nixos.org/manual/nixos/stable/) for general NixOS documentation.

See the [Home Manager Manual](https://nix-community.github.io/home-manager/) for user environment configuration.

## Current Hosts

**tile** - ThinkPad T490s running NixOS unstable with Hyprland

## Credits

Inspired by:
- [bbigras/nix-config](https://github.com/bbigras/nix-config) - Modular configuration structure
- [NixOS community](https://nixos.org/community/) - Countless examples and support
- [Claude](https://claude.ai) - The real captain now (I use Claude btw)
