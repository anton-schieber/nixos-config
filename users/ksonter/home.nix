#
# Description:
#   Home Manager configuration for user 'ksonter'.
#
# Usage:
#   Import this file from the corresponding user.nix:
#       home-manager.users.ksonter = import ./home.nix;
#
{ ... }:

{
  # Pins Home Manager defaults a specific NixOS version
  home.stateVersion = "25.11";
  # Git configuration
  programs.git = {
    enable = true;
    userName = "Kieran Sonter";
    userEmail = "ksonter95@gmail.com";
  };
}
