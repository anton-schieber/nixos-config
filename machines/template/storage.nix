#
# Description:
#   Storage configuration. This file defines how the machine stores and manages data.
#
#   Disks must be provisioned using provisioning/disko/data.nix and mounted at
#   /srv/disks/data{N} before use.
#
# Usage:
#   Import this module from the machine's configuration.nix:
#       imports = [
#         ./storage.nix
#       ];
#
# Notes:
#   - Provision all disks using provisioning/disko/data.nix with --bay N flag
#   - Mount points must follow the pattern /srv/disks/data{N}
#   - Parity disk must be at least as large as the largest data disk
#

{ ... }:

{
  imports = [
    ../../modules/nixos/storage
  ];

  nixos.storage.parityBays = [ 1 ];
  nixos.storage.dataBays = [ 2 3 ];
}
