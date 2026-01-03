#
# Description:
#   flake.nix is the entry point for the entire repository and defines all flake inputs
#   and outputs. It is the single source of truth for how NixOS systems are composed,
#   built, and installed from this repository.
#
#   The flake defines one nixosConfiguration per physical NAS machine. Each configuration
#   assembles machine-specific files under machines/<name>/ together with shared NixOS
#   modules. Machine configurations are responsible for enabling optional components such
#   as Home Manager.
#
#   This repository is designed to manage multiple machines from a single shared flake
#   while keeping machine-specific differences explicit and isolated.
#
# Usage:
#   Install NixOS for a specific machine from the repository root:
#       sudo nixos-install --flake .#nas-a
#
#   Rebuild a running system for a specific machine:
#       sudo nixos-rebuild switch --flake .#nas-a
#
# Notes:
#   - Machine names must match:
#       * directory name under machines/
#       * nixosConfigurations key in this file
#       * networking.hostName for the machine
#   - This file must remain free of machine-specific configuration.
#   - All runtime behavior is defined in imported modules and machine files.
#

{
  description = "Shared flake for identical NixOS-based NAS machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations = {
      # Template NAS machine
      template = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
        };
        modules = [
          ./machines/template/configuration.nix
        ];
      };
    };
  };
}
