#
# Description:
#   Default networking policy. This module enables NetworkManager and configures all
#   network interfaces to use DHCP with a firewall.
#
# Usage:
#   Import this module from a machine configuration:
#       imports = [
#         ../../modules/nixos/system/networking
#       ];
#

{ ... }:

{
  imports = [
    ../default.nix
  ];

  # Enable NetworkManager as the primary network management service
  networking.networkmanager.enable = true;
  # Enable DHCP for all network interfaces by default
  networking.useDHCP = true;
  # Enable the system firewall with default rules
  networking.firewall.enable = true;
}
