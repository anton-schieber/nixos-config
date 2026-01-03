#
# Description:
#   Storage configuration. This file defines how the machine stores and manages data.
#
#   Disks must be provisioned using provisioning/disko/disk.nix and mounted at
#   /srv/disks/bay{N} before use.
#
# Usage:
#   Import this module from the machine's configuration.nix:
#       imports = [
#         ./storage.nix
#       ];
#
# Notes:
#   - Provision all disks using provisioning/disko/disk.nix with --bay N flag
#   - Mount points must follow the pattern /srv/disks/bay{N}
#   - Parity disk must be at least as large as the largest data disk
#

{ ... }:

{
  imports = [
    ../../modules/nixos/storage/snapraid.nix
    ../../modules/nixos/storage/filesystem/bay3.nix
    ../../modules/nixos/storage/filesystem/bay4.nix
    ../../modules/nixos/storage/filesystem/bay5.nix
  ];

  # SnapRAID configuration
  nixos.storage.snapraid.parityBays = [ 3 ];
  nixos.storage.snapraid.dataBays = [ 4 5 ];
}
