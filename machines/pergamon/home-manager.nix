#
# Description:
#   Home Manager configuration. This file defines which Home Manager modules run on the
#   machine.
#
# Usage:
#   Import this file from the machine's configuration.nix:
#       imports = [
#         ./home-manager.nix
#       ];
#

{ ... }:

{
  imports = [
    ../../modules/home-manager
  ];
}
