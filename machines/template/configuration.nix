#
# Description:
#   Top-level NixOS configuration for this machine. This file composes generated hardware
#   identity, machine-specific configuration, and shared policy modules.
#
#   This file must remain small and declarative. It should primarily import other files
#   rather than contain large configuration blocks itself.
#
# Usage:
#   Include this module in the flake definition for the target machine:
#       modules = [
#           ./machines/template/configuration.nix
#       ];
#

{ inputs, ... }:

{
  imports = [
    # Auto-generated
    ./generated/hardware.nix

    # Machine-specific
    ./compatibility.nix
    ./home-manager.nix
    ./programs.nix
    ./services.nix
    ./storage.nix
    ./system.nix
    ./users.nix
  ];

  # Pins configuration to a specific NixOS version
  system.stateVersion = "25.11";
}
