#
# Description:
#   Default storage filesystem policy.
#
# Usage:
#   Import this module from a machine configuration:
#       imports = [
#         ../../modules/nixos/storage/filesystem
#       ];
#

{ ... }:

{
  imports = [
    ../default.nix
  ];
}
