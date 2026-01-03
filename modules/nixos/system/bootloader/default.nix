#
# Description:
#   Default system bootloader policy.
#
# Usage:
#   Import this module from a machine configuration:
#       imports = [
#         ../../modules/nixos/system/bootloader
#       ];
#

{ ... }:

{
  imports = [
    ../default.nix
  ];
}
