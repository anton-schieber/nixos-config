#
# Description:
#   Base NixOS user account definition for user 'ksonter'. This file is reusable across
#   machines, meaning machine-specific configuration is avoided.
#
# Usage:
#   Import this file from the machine users.nix:
#       imports = [
#           ../../users/ksonter/user.nix
#       ];
#
{ pkgs, ... }:

{
  users.groups.ksonter = {
    # Stable GID across machines to avoid ownership mismatches
    gid = 1000;
  };
  users.users.ksonter = {
    # Normal (non-system) user account
    isNormalUser = true;
    # Stable UID across machines to avoid ownership mismatches
    uid = 1000;
    # User's primary group
    group = "ksonter";
    # User's shell
    shell = pkgs.zsh;
    # Authorised server-side SSH keys
    openssh.authorizedKeys.keys = [];
  };
  # Wire Home Manager configuration
  home-manager.users.ksonter = import ./home.nix;
}
