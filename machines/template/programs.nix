#
# Description:
#   Programs configuration. This file defines which system programs are enabled.
#
# Usage:
#   Import this file from the machine's configuration.nix:
#       imports = [
#         ./programs.nix
#       ];
#

{ ... }:

{
  imports = [
    ../../modules/nixos/programs
  ];
}
