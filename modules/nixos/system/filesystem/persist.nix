#
# Description:
#   Persistent filesystem configuration. This module applies consistent mount options to
#   the /persist filesystem.
#
# Usage:
#   Import this module from a machine configuration:
#       imports = [
#         ../../modules/nixos/system/filesystem/persist.nix
#       ];
#

{ lib, ... }:

{
  imports = [
    ./default.nix
  ];

  # Apply consistent mount options for /persist filesystem
  fileSystems."/persist" = {
    options = lib.mkAfter [
      "compress=zstd"
      "ssd"
      "discard=async"
    ];
  };
}
