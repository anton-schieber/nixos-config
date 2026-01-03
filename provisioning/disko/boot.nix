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
#   Optional subvolumes can be enabled via the subvolumes attrset:
#     - subvolumes.createHome    : boolean, creates @home subvolume (default: false)
#     - subvolumes.createLog     : boolean, creates @log subvolume (default: false)
#     - subvolumes.createNix     : boolean, creates @nix subvolume (default: false)
#     - subvolumes.createPersist : boolean, creates @persist subvolume (default: false)
#
# Usage:
#   Run disko directly against boot.nix (note: executed from repository root):
#       sudo nix
#           --experimental-features "nix-command flakes"
#           run github:nix-community/disko --
#           --mode disko
#           --arg disk '{ device = "/dev/disk/by-id/nvme-XXXX"; }'
#           --arg subvolumes '{ createLog = true; }'
#           ./modules/disko/boot.nix
#

{ disk, subvolumes ? {}, lib, ... }:

let
  # Default all subvolume flags to false
  createLog = subvolumes.createLog or false;
  createNix = subvolumes.createNix or false;
  createPersist = subvolumes.createPersist or false;
  createHome = subvolumes.createHome or false;
in
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
                preFormatScript = ''
                  wipefs --all --force "$device" || true
                '';
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "ssd" "discard=async" ];
                  };
                } // lib.optionalAttrs createHome {
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" "ssd" "discard=async" ];
                  };
                } // lib.optionalAttrs createLog {
                  "@log" = {
                    mountpoint = "/var/log";
                    mountOptions = [ "compress=zstd" "ssd" "discard=async" ];
                  };
                } // lib.optionalAttrs createNix {
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "ssd" "discard=async" ];
                  };
                } // lib.optionalAttrs createPersist {
                  "@persist" = {
                    mountpoint = "/persist";
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
