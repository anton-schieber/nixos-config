#
# Description:
#   System configuration. This file defines core system settings.
#
# Usage:
#   Import this file from the machine'a configuration.nix:
#       imports = [
#         ./system.nix
#       ];
#

{ ... }:

{
  imports = [
    ../../modules/nixos/system/bootloader/systemd-boot.nix
    ../../modules/nixos/system/filesystem/root.nix
    ../../modules/nixos/system/networking
  ];

  # Machine identity
  networking.hostName = "template";
  # System timezone used for logs, timers, and all system time calculations
  time.timeZone = "Australia/Brisbane";
  # Default locale used system-wide for language and formatting preferences
  i18n.defaultLocale = "en_AU.UTF-8";
}
