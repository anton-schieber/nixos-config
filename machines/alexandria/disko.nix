{ disks ? { } }:
{
  disko.devices = {
    disk = {
      nvme-boot = {
        device = disks.nvme1 or "/dev/nvme0n1";
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
              };
            };
            swap = {
              size = "8G";
              content = {
                type = "swap";
                resumeDevice = true;
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "ssd" "discard=async" ];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" "ssd" "discard=async" ];
                  };
                };
              };
            };
          };
        };
      };

      # Cache drive
      sata1 = {
        device = disks.sata1 or "/dev/sdb";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            cache = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/mnt/cache1";
                mountOptions = [ "defaults" "noatime" "nofail" ];
              };
            };
          };
        };
      };
        sata2 = {
        device = disks.sata2 or "/dev/sda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            cache = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/mnt/cache2";
                mountOptions = [ "defaults" "noatime" "nofail" ];
              };
            };
          };
        };
      };

      # HDD storage drive
      sata6 = {
        device = disks.sata6 or "/dev/sdd";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            storage = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/mnt/storage3";
                mountOptions = [ "defaults" "noatime" "nofail" ];
              };
            };
          };
        };
      };
      sata8 = {
        device = disks.sata8 or "/dev/sde";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            storage = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/mnt/storage1";
                mountOptions = [ "defaults" "noatime" "nofail" ];
              };
            };
          };
        };
      };
    };
  };
}