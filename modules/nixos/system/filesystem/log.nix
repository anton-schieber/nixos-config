#
# Description:
#   Log filesystem configuration. This module applies consistent mount options to the
#   /var/log filesystem.
#
# Usage:
#   Import this module from a machine configuration:
#       imports = [
#         ../../modules/nixos/system/filesystem/log.nix
#       ];
#

{ lib, ... }:

{
  imports = [
    ./default.nix
  ];

  # Apply consistent mount options for /var/log filesystem
  fileSystems."/var/log" = {
    options = lib.mkAfter [
      "compress=zstd"
      "ssd"
      "discard=async"
    ];
  };
}
