#
# Description:
#   User configuration. This file selects which users exist on this machine, applies
#   machine-specific group membership, and wires users to their per-user Home Manager
#   configurations.
#
# Usage:
#   Import this file from the machine's configuration.nix:
#       imports = [
#         ./users.nix
#       ];
#

{ lib, ... }:

{
  imports = [
    ../../users/ksonter/user.nix
  ];

  # === User: ksonter === #
  # Assign machine-specific groups
  users.users.ksonter.extraGroups = lib.mkAfter [
    "wheel"
  ];
}
