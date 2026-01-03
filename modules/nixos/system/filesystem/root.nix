#
# Description:
#   Root filesystem configuration. This module applies consistent mount options to the
#   / filesystem.
#
# Usage:
#   Import this module from a machine configuration:
#       imports = [
#         ../../modules/nixos/system/filesystem/root.nix
#       ];
#

{ lib, ... }:

{
  imports = [
    ./default.nix
  ];

  # Apply consistent mount options for / filesystem
  fileSystems."/" = {
    options = lib.mkAfter [
      "compress=zstd"
      "ssd"
      "discard=async"
    ];
  };
}
