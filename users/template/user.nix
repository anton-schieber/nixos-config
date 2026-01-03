#
# Description:
#   Base NixOS user account definition for user 'template'. This file is reusable across
#   machines, meaning machine-specific configuration is avoided.
#
# Usage:
#   Import this file from the machine users.nix:
#       imports = [
#           ../../users/template/user.nix
#       ];
#
{ pkgs, ... }:

{
  users.groups.template = {
    # Stable GID across machines to avoid ownership mismatches
    gid = 9999;
  };
  users.users.template = {
    # Normal (non-system) user account
    isNormalUser = true;
    # Stable UID across machines to avoid ownership mismatches
    uid = 9999;
    # User's primary group
    group = "template";
    # User's shell
    shell = pkgs.zsh;
    # Authorised server-side SSH keys
    openssh.authorizedKeys.keys = [];
  };
  # Wire Home Manager configuration
  home-manager.users.template = import ./home.nix;
}
