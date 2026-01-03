#
# Description:
#   disk.nix is a provisioning-only disko module used to initialise a single new data disk
#   for later use in the snapRAID + mergerfs storage stack. It is intentionally
#   destructive and must never be imported into a running host configuration.
#
#   The module wipes the target disk, creates a fresh GPT partition table, formats the
#   disk with a single ext4 filesystem, and mounts it at /srv/disks/bay{N}.
#
#   The ext4 filesystem is labelled based on the bay position (slots 1-8).
#
#   Disk identity is provided externally via the disk attrset:
#     - disk.device : stable by-id path of the new disk to be wiped (required)
#     - disk.bay    : integer bay number (1-8), required
#
# Usage:
#   sudo nix
#       --experimental-features "nix-command flakes"
#       run github:nix-community/disko --
#       --mode disko
#       --arg disk '{ device = "/dev/disk/by-id/XXXX"; bay = 3; }'
#       ./modules/disko/disk.nix
#

{ disk, lib, ... }:

{
  assertions = [
    {
      assertion = disk ? device;
      message = "disk.nix requires disk.device to be specified.";
    }
    {
      assertion = disk ? bay;
      message = "disk.nix requires disk.bay to be specified.";
    }
    {
      assertion = builtins.isInt disk.bay && disk.bay >= 1 && disk.bay <= 8;
      message = "disk.bay must be an integer in the range 1-8.";
    }
  ];

  disko.devices = {
    disk = {
      "bay${toString disk.bay}" = {
        device = disk.device;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            data = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/srv/disks/bay${toString disk.bay}";
                mountOptions = [ "defaults" "noatime" "nofail" ];
                extraArgs = [ "-L" "bay${toString disk.bay}" ];
              };
            };
          };
        };
      };
    };
  };
}