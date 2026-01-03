#
# Description:
#   Disk management utilities. This module provides tools for disk provisioning and
#   management.
#
# Usage:
#   Import this module from a machine configuration:
#       imports = [
#         ../../modules/nixos/programs/disk.nix
#       ];
#

{ pkgs, ... }:

{
  imports = [
    ./default.nix
  ];

  # Disk management utilities
  environment.systemPackages = with pkgs; [
    gptfdisk   # sgdisk for GPT partition management
    util-linux # wipefs for wiping filesystem signatures
  ];
}
