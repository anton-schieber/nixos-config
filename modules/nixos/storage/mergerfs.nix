#
# Description:
#   MergerFS configuration module for pooling multiple data disks into a single mount
#   point. This module configures MergerFS to combine multiple data disks at
#   /srv/disks/data{N} into a unified filesystem at /srv/storage.
#
#   This module provides a common baseline configuration that can be customized per
#   machine via the nixos.storage.mergerfs options. Machine-specific configuration uses a
#   bay-based approach where disks are identified by their physical bay position.
#
# Usage:
#   Import this module from a machine configuration:
#       imports = [
#         ../../modules/nixos/storage/mergerfs.nix
#       ];
#   Configure MergerFS:
#       nixos.storage.mergerfs = {
#         dataBays = [ 3 4 5 ];
#       };
#
# Notes:
#   - Requires at least one data bay
#   - Disks must be mounted at /srv/disks/data{N} before mergerfs can pool them
#   - Mount point is always /srv/storage
#   - Uses 'eplfs' (existing path, least free space) for create policy
#   - Automatically mounts at boot after disk mounts are ready
#

{ pkgs, lib, config, ... }:

let
  # Generate paths from bay numbers
  dataPaths =
    map (bay: "/srv/disks/data${toString bay}")
    config.nixos.storage.mergerfs.dataBays;
in
{
  options.nixos.storage.mergerfs = {
    dataBays = lib.mkOption {
      type = lib.types.listOf lib.types.int;
      description = ''
        List of physical bay numbers containing data disks to pool.
        Each disk must be mounted at /srv/disks/data{N}.
        At least one data bay is required for mergerfs operation.
      '';
      example = [ 3 4 5 ];
    };
  };

  config = lib.mkIf (builtins.length config.nixos.storage.mergerfs.dataBays > 0) {
    assertions = [
      {
        assertion = builtins.length config.nixos.storage.mergerfs.dataBays >= 1;
        message = "MergerFS requires at least one data bay.";
      }
      {
        assertion =
          builtins.all (bay: bay > 0) config.nixos.storage.mergerfs.dataBays;
        message = "All MergerFS data bay numbers must be positive integers.";
      }
      {
        assertion =
          builtins.length (lib.unique config.nixos.storage.mergerfs.dataBays)
          == builtins.length config.nixos.storage.mergerfs.dataBays;
        message = "MergerFS data bays must be unique.";
      }
    ];

    # Install mergerfs package
    environment.systemPackages = [ pkgs.mergerfs ];
    # Create mount point directory
    systemd.tmpfiles.rules = [
      "d /srv/storage 0777 root root -"
    ];

    # Configure mergerfs mount
    fileSystems."/srv/storage" = {
      device = lib.concatStringsSep ":" dataPaths;
      fsType = "fuse.mergerfs";
      options = [
        "defaults"
        "allow_other"
        "use_ino"
        "cache.files=partial"
        "dropcacheonclose=true"
        "category.create=eplfs"  # Existing path, least free space
        "moveonenospc=true"
        "minfreespace=10G"
        "fsname=mergerfs"
      ];
    };
  };
}
