#
# Description:
#   disk.nix is a provisioning-only disko module used to initialise a single new data disk
#   for later use in the snapRAID + mergerfs storage stack. It is intentionally
#   destructive and must never be imported into a running host configuration.
#
#   The module wipes the target disk, creates a fresh GPT partition table, formats the
#   disk with a single ext4 filesystem, and mounts it at a temporary provisioning
#   mountpoint.
#
#   Optionally, the ext4 filesystem may be labelled based on the NAS bay position
#   (slots 1-8). If no bay is specified, the filesystem is created without a label.
#
#   Disk identity is provided externally via the disk attrset:
#     - disk.device : stable by-id path of the new disk to be wiped (required)
#     - disk.bay    : integer bay number (1-8), optional
#
# Usage:
#   With bay label:
#       sudo nix
#           --experimental-features "nix-command flakes"
#           run github:nix-community/disko --
#           --mode disko
#           --arg disk '{ device = "/dev/disk/by-id/XXXX"; bay = 3; }'
#           ./modules/disko/disk.nix
#
#   Without bay label:
#       sudo nix
#           --experimental-features "nix-command flakes"
#           run github:nix-community/disko --
#           --mode disko
#           --arg disk '{ device = "/dev/disk/by-id/XXXX"; }'
#           ./modules/disko/disk.nix
#

{ disk, lib, ... }:

let
  label =
    if disk ? bay
    then "nas-bay${toString disk.bay}"
    else null;
in
{
  assertions = [
    {
      assertion = disk ? device;
      message = "disk.nix requires disk.device to be specified.";
    }
    {
      assertion =
        label == null
        || (builtins.isInt disk.bay && disk.bay >= 1 && disk.bay <= 8);
      message = "disk.bay must be an integer in the range 1-8 when specified.";
    }
  ];

  disko.devices = {
    disk = {
      target = {
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
                mountpoint = "/mnt/provision";
                extraArgs = lib.optionals (label != null) [ "-L" label ];
              };
            };
          };
        };
      };
    };
  };
}