#
# Description:
#   boot.nix is a provisioning-only disko module that defines the complete layout of the
#   boot SSD. It declaratively specifies the partition table, filesystems, subvolumes,
#   mountpoints, and mount options required for the operating system to boot and run.
#
#   The module is intentionally limited to the boot NVMe only and must never reference
#   HDDs. Disk identity is provided externally via the disk attrset:
#     - disk.device : stable by-id path of the boot disk to be wiped (required)
#
# Usage:
#   Run disko directly against boot.nix (note: executed from repository root):
#       sudo nix
#           --experimental-features "nix-command flakes"
#           run github:nix-community/disko --
#           --mode disko
#           --arg disk '{ device = "/dev/disk/by-id/nvme-XXXX"; }'
#           ./modules/disko/boot.nix
#

{ disk, lib, ... }:

{
  assertions = [
    {
      assertion = disk ? device;
      message = "boot.nix requires disk.device to be specified.";
    }
  ];

  disko.devices = {
    disk = {
      boot-disk = {
        device = disk.device;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "fmask=0077" "dmask=0077" ];
                extraArgs = [ "-n" "EFI" ];
              };
            };

            swap = {
              size = "8G";
              content = {
                type = "swap";
                resumeDevice = true;
                extraArgs = [ "-L" "swap" ];
              };
            };

            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" "-L" "root" ];
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "ssd" "discard=async" ];
                  };

                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "ssd" "discard=async" ];
                  };

                  "@persist" = {
                    mountpoint = "/persist";
                    mountOptions = [ "compress=zstd" "ssd" "discard=async" ];
                  };

                  "@var-log" = {
                    mountpoint = "/var/log";
                    mountOptions = [ "compress=zstd" "ssd" "discard=async" ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
