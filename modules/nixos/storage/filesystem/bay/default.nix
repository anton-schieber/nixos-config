#
# Description:
#   Shared function for generating bay filesystem configurations. This function creates a
#   module that applies consistent mount options to a specific bay filesystem mounted at
#   /srv/disks/bay{N}.
#
# Usage:
#   This file should not be imported directly. Instead, import specific bay files like
#   bay1.nix, bay2.nix, etc.
#

{ lib }:

bayNumber:

{ lib, ... }:

{
  imports = [
    ../default.nix
  ]

  # Apply consistent mount options for /srv/disks/bay{N} filesystem
  fileSystems."/srv/disks/bay${toString bayNumber}" = {
    options = lib.mkAfter [
      "defaults"
      "noatime"
      "nofail"
    ];
  };
}
