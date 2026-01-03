#
# Description:
#   Services configuration. This file defines which services run on the machine.
#
# Usage:
#   Import this file from the machine's configuration.nix:
#       imports = [
#         ./services.nix
#       ];
#

{ ... }:

{
  imports = [
    ../../modules/nixos/services/ssh.nix
  ];
}
