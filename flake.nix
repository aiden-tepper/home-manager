{
  description = "Aiden's Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      lib = nixpkgs.lib;
      
      # macOS system configuration
      darwinSystem = "aarch64-darwin";
      darwinPkgs = import nixpkgs { system = darwinSystem; };
      
      # Linux system configuration
      linuxSystem = "x86_64-linux";
      linuxPkgs = import nixpkgs { system = linuxSystem; };
    in {
      homeConfigurations = {
        macbook = home-manager.lib.homeManagerConfiguration {
          pkgs = darwinPkgs;
          modules = [ ./hosts/macbook.nix ];
        };
        
        spectre = home-manager.lib.homeManagerConfiguration {
          pkgs = linuxPkgs;
          modules = [ ./hosts/spectre.nix ];
        };
      };
    };
}
