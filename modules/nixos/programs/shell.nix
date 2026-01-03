#
# Description:
#   Shell configuration. This module enables shell programs and utilities.
#
# Usage:
#   Import this module from a machine configuration:
#       imports = [
#         ../../modules/nixos/programs/shell.nix
#       ];
#

{ ... }:

{
  imports = [
    ./default.nix
  ];

  # Enable zsh shell
  programs.zsh.enable = true;
}
