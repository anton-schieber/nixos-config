#
# Description:
#   Home Manager configuration for user 'template'.
#
# Usage:
#   Import this file from the corresponding user.nix:
#       home-manager.users.template = import ./home.nix;
#
{ ... }:

{
  # Pins Home Manager defaults a specific NixOS version
  home.stateVersion = "25.11";
}
