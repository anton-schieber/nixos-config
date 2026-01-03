#
# Description:
#   Default system filesystem policy.
#
# Usage:
#   Import this module from a machine configuration:
#       imports = [
#         ../../modules/nixos/system/filesystem
#       ];
#

{ ... }:

{
  imports = [
    ../default.nix
  ];
}
