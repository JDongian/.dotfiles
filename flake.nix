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
          };
        }
      ];
    };

    # Keep 'default' as an alias to current machine for convenience
    nixosConfigurations.default = self.nixosConfigurations.tile;
  };
}
