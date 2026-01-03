#
# Description:
#   SSH service configuration. This module enables and configures OpenSSH for remote
#   access.
#
# Usage:
#   Import this module from a machine configuration:
#       imports = [
#         ../../modules/nixos/services/ssh.nix
#       ];
#

{ pkgs, lib, ... }:

{
  imports = [
    ./default.nix
  ];

  # Enable the OpenSSH server for remote administration
  services.openssh.enable = true;
  # Disable SSH login as root
  services.openssh.settings.PermitRootLogin = "no";
  # Open SSH port in the firewall
  networking.firewall.allowedTCPPorts = lib.mkAfter [ 22 ];
}
