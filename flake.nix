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
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";  # stable release
    hyprpanel.url = "github:Jas-SinghFSU/HyprPanel";
    home-manager = {
      url = "github:nix-community/home-manager";  # Match nixpkgs version
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, ... }@inputs: let
    system = "x86_64-linux";
  in {
    nixosConfigurations.default = nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs;
        inherit system;
      };
      modules = [
        ./configuration.nix
        inputs.home-manager.nixosModules.default
        {nixpkgs.overlays = [inputs.hyprpanel.overlay];}
        {
          # Configure Home Manager for user joshua
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.joshua = import ./home.nix;
        }
      ];
    };
  };
}
