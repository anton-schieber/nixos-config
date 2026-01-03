#
# Description:
#   Nix store filesystem configuration. This module applies consistent mount options to
#   the /nix filesystem.
#
# Usage:
#   Import this module from a machine configuration:
#       imports = [
#         ../../modules/nixos/system/filesystem/nix.nix
#       ];
#

{ lib, ... }:

{
  imports = [
    ./default.nix
  ];

  # Apply consistent mount options for /nix filesystem
  fileSystems."/nix" = {
    options = lib.mkAfter [
      "compress=zstd"
      "ssd"
      "discard=async"
    ];
  };
}
