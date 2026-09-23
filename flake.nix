{
  description = "Nixos config flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Tracks home-manager master. nixpkgs is pinned via `follows` below so HM
    # and the system share one nixpkgs; stateVersion stays 24.11 regardless.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mcmojave-hyprcursor.url = "github:libadoxon/mcmojave-hyprcursor";
    claude-code-overlay = {
      url = "github:ryoppippi/claude-code-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, ... }@inputs: let
    system = "x86_64-linux";

    # Wi-Fi profiles staged by scripts/stage-wifi.sh into /etc/nixos/wifi-secrets.
    # They are gitignored (plaintext PSKs; this repo is public) and therefore
    # absent from `self`, so they are imported into the store explicitly.
    #
    # Requires --impure when the directory exists, because it reads a path
    # outside the flake. `nix build .#installer` alone will NOT pick these up;
    # use scripts/build-iso.sh, which passes the flag and says what it is doing.
    wifiDir =
      let p = builtins.getEnv "OBSIDIAN_WIFI_DIR";
      in if p != "" && builtins.pathExists p
         then builtins.path { path = p; name = "obsidian-wifi-secrets"; }
         else null;
  in {
    # ThinkPad T490s configuration
    nixosConfigurations.tile = nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs;
        inherit system;
      };
      modules = [
        ./hosts/tile
        inputs.home-manager.nixosModules.default
        {
          nixpkgs.overlays = [
            # claude-code from the overlay's default output. This is the SINGLE
            # source of truth for claude. Its built-in npm-global auto-updater
            # otherwise reinstalls a ~/.nvm/.../@anthropic-ai/claude-code copy
            # that shadows this on PATH and drifts — disabled durably via
            # DISABLE_AUTOUPDATER=1 in home.nix (home.sessionVariables). See the
            # claude_nix_single_source note for the full story.
            # To bump: `nix flake update claude-code-overlay`, which moves the
            # input revision so `.default` tracks a newer release. The pinned
            # revision does NOT expose per-version attrs (e.g. ."2.1.161"),
            # so don't reference them — it fails eval with "attribute missing".
            inputs.claude-code-overlay.overlays.default
          ];
        }
        {
          # Configure Home Manager for user joshua
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.joshua = { config, pkgs, lib, ... }: {
            imports = [ ./home.nix ];
            # Tile-specific monitor config (1920x1080)
            home.file.".config/hypr/monitor.conf".source = ./dotfiles/hypr/hosts/tile-monitor.conf;
            # Tile-specific terminal font size (gohufont 11px)
            home.file.".config/foot/font.ini".source = ./dotfiles/foot/hosts/tile-font.ini;
            # Tile-specific waybar font size (10px)
            home.file.".config/waybar/font.css".source = ./dotfiles/waybar/hosts/tile-font.css;
          };
        }
      ];
    };

    # X1 Carbon configuration
    nixosConfigurations.gravel = nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs;
        inherit system;
      };
      modules = [
        inputs.disko.nixosModules.disko
        ./hosts/gravel
        inputs.home-manager.nixosModules.default
        {
          nixpkgs.overlays = [
            # claude-code from the overlay default; keep in sync with the tile
            # host above. Bump via `nix flake update claude-code-overlay`.
            inputs.claude-code-overlay.overlays.default
          ];
        }
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.joshua = { config, pkgs, lib, ... }: {
            imports = [ ./home.nix ];
            # Gravel-specific monitor config (2560x1440)
            home.file.".config/hypr/monitor.conf".source = ./dotfiles/hypr/hosts/gravel-monitor.conf;
            # Gravel-specific terminal font size (gohufont 11px)
            home.file.".config/foot/font.ini".source = ./dotfiles/foot/hosts/gravel-font.ini;
            # Gravel-specific waybar font size (10px)
            home.file.".config/waybar/font.css".source = ./dotfiles/waybar/hosts/gravel-font.css;
          };
        }
      ];
    };

    # ThinkPad X1 Carbon 7th gen configuration.
    # Mirrors `tile` as closely as the hardware allows: same configuration.nix,
    # same home.nix, same overlays. Differences are confined to hosts/obsidian
    # (hardware quirks + power) and disko-obsidian.nix (disk layout).
    nixosConfigurations.obsidian = nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs;
        inherit system;
      };
      modules = [
        inputs.disko.nixosModules.disko
        ./hosts/obsidian
        inputs.home-manager.nixosModules.default
        {
          nixpkgs.overlays = [
            # claude-code from the overlay default; keep in sync with tile.
            # Bump via `nix flake update claude-code-overlay`.
            inputs.claude-code-overlay.overlays.default
          ];
        }
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.joshua = { config, pkgs, lib, ... }: {
            imports = [ ./home.nix ];
            # Obsidian-specific monitor config (2560x1440 WQHD)
            home.file.".config/hypr/monitor.conf".source =
              ./dotfiles/hypr/hosts/obsidian-monitor.conf;
            # Obsidian-specific terminal font size: gohufont 14px, one bitmap
            # step up from the 11px the other hosts use.
            home.file.".config/foot/font.ini".source =
              ./dotfiles/foot/hosts/obsidian-font.ini;
            # Obsidian-specific waybar font size: 14px, matching the terminal.
            home.file.".config/waybar/font.css".source =
              ./dotfiles/waybar/hosts/obsidian-font.css;
          };
        }
      ];
    };

    # --- Installer ISO for obsidian ------------------------------------------
    # Build:  nix build .#installer
    # Result: ./result/iso/nixos-obsidian-installer.iso
    #
    # Embeds this repo AND the full obsidian store closure, so the install on
    # the X1 runs entirely offline at exactly the revision built here.
    #
    # NOTE: if wifi-secrets/ is staged (scripts/stage-wifi.sh), the resulting
    # ISO CONTAINS PLAINTEXT Wi-Fi PASSWORDS. Treat the USB accordingly.
    nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs system;
        obsidianSystem = self.nixosConfigurations.obsidian.config.system.build.toplevel;
        # The flake source tree (git-tracked files only).
        repoSrc = self;
        # Staged Wi-Fi profiles. Set via the `wifiDir` flake-level argument
        # below; null when not staged, in which case the ISO still builds and
        # simply carries no credentials.
        #
        # TWO TRAPS, both of which fail SILENTLY (no error, just an ISO with
        # zero Wi-Fi profiles) and both of which were hit while writing this:
        #   1. It cannot come from `self`: wifi-secrets/ is gitignored, and a
        #      git flake's `self` contains only GIT-TRACKED files.
        #   2. It cannot be a bare path literal like /etc/nixos/wifi-secrets:
        #      under PURE flake evaluation, builtins.pathExists on a path
        #      outside the flake returns false rather than erroring.
        # Hence the explicit builtins.path import below, which is the only
        # form that both reaches outside the flake and works in pure eval.
        inherit wifiDir;
      };
      modules = [ ./installer/iso.nix ];
    };

    packages.${system}.installer =
      self.nixosConfigurations.installer.config.system.build.isoImage;

    # Keep 'default' as an alias to current machine for convenience
    nixosConfigurations.default = self.nixosConfigurations.tile;
  };
}
