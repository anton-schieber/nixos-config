#
# Description:
#   Systemd-boot bootloader configuration.
#
# Usage:
#   Import this module from a machine configuration:
#       imports = [
#         ../../modules/nixos/system/bootloader/systemd-boot.nix
#       ];
#

{ ... }:

{
  imports = [
    ./default.nix
  ];

  # Use the systemd-boot EFI bootloader
  boot.loader.systemd-boot.enable = true;
  # Allow modification of UEFI firmware boot entries during installation and upgrades
  boot.loader.efi.canTouchEfiVariables = true;
}
