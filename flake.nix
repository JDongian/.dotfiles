# {
#   description = "Nixos config flake";
#   inputs = {
#     nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";  # stable release
#     hyprpanel.url = "github:Jas-SinghFSU/HyprPanel";
#     home-manager = {
#       url = "github:nix-community/home-manager/release-24.11";  # Match nixpkgs version
#       inputs.nixpkgs.follows = "nixpkgs";
#     };
#   };
#   outputs = { self, nixpkgs, ... }@inputs: let
#     system = "x86_64-linux";
#   in {
#     nixosConfigurations.default = nixpkgs.lib.nixosSystem {
#       specialArgs = {
#         inherit inputs;
#         inherit system;
#       };
#       modules = [
#         ./configuration.nix
#         inputs.home-manager.nixosModules.default
#       ];
#     };
#   };
# }

{
  description = "Nixos config flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # hyprpanel is now in nixpkgs, no need for overlay anymore
    # hyprpanel.url = "github:Jas-SinghFSU/HyprPanel";
    home-manager = {
      url = "github:nix-community/home-manager";  # Match nixpkgs version
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
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
        # hyprpanel overlay removed - hyprpanel is now available in nixpkgs
        # {nixpkgs.overlays = [inputs.hyprpanel.overlay];}
        {
          # Configure Home Manager for user joshua
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
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
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
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
