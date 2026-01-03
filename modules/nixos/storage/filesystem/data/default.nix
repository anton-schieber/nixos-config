#
# Description:
#   Shared function for generating data disk filesystem configurations. This function
#   creates a module that applies consistent mount options to a specific data disk
#   filesystem mounted at /srv/disks/data{N}.
#
# Usage:
#   This file should not be imported directly. Instead, import specific data disk files
#   like data1.nix, data2.nix, etc.
#

bayNumber:

{ lib, ... }:

{
  imports = [
    ../default.nix
  ];

  # Apply consistent mount options for /srv/disks/data{N} filesystem
  fileSystems."/srv/disks/data${toString bayNumber}" = {
    options = lib.mkAfter [
      "defaults"
      "noatime"
      "nofail"
    ];
  };
}
