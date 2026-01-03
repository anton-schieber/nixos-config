#
# Description:
#   Default compatibility policy. This module enables nix-ld with common runtime libraries
#   needed for all binaries not built for NixOS.
#
# Usage:
#   Import this module from a machine configuration:
#       imports = [
#         ../../modules/nixos/compatibility
#       ];
#

{ pkgs, lib, ... }:

{
  # Enable nix-ld for running dynamically linked binaries not built for NixOS
  programs.nix-ld.enable = true;
  # Provide standard C/C++ libraries for dynamically linked binaries
  programs.nix-ld.libraries = lib.mkAfter (with pkgs; [
    stdenv.cc.cc
  ]);
}

