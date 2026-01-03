#
# Description:
#   Home filesystem configuration. Tis module applies consistent mount options to the
#   /home filesystem.
#
# Usage:
#   Import this module from a machine configuration:
#       imports = [
#         ../../modules/nixos/system/filesystem/home.nix
#       ];
#

{ lib, ... }:

{
  imports = [
    ./default.nix
  ];

  # Apply consistent mount options for /home filesystem
  fileSystems."/home" = {
    options = lib.mkAfter [
      "compress=zstd"
      "ssd"
      "discard=async"
    ];
  };
}
