#
# Description:
#   Default programs policy. This module enables programs that are commonly used
#   system-wide.
#
# Usage:
#   Import this module from a machine configuration:
#       imports = [
#         ../../modules/nixos/programs
#       ];
#

{ ... }:

{
  # Enable zsh shell
  programs.zsh.enable = true;
}
