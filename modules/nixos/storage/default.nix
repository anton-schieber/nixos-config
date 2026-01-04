#
# Description:
#   Default storage policy which uses a combination of SnapRAID and MergerFS.
#
# Usage:
#   Import this module from a machine configuration:
#       imports = [
#           ../../modules/nixos/storage
#       ];
#       nixos.storage.parityBays = [ 1 ];
#       nixos.storage.dataBays = [ 2 3 ];
#

{ ... }:

{
  imports = [
    ./mergerfs.nix
    ./snapraid.nix
  ] ++ (map (bay: ./filesystem + "/data" + toString bay + ".nix")
      (config.nixos.storage.parityBays ++ config.nixos.storage.dataBays));

  options.nixos.storage = {
    parityBays = lib.mkOption {
      type = lib.types.listOf lib.types.int;
      description = ''
        List of physical bay numbers containing parity disks for SnapRAID.
        Each disk must be mounted at /srv/disks/data{N}.
        At least one parity bay is required for SnapRAID operation.
      '';
      example = [ 1 ];
    };
    dataBays = lib.mkOption {
      type = lib.types.listOf lib.types.int;
      description = ''
        List of physical bay numbers containing data disks for both SnapRAID and mergerfs.
        Each disk must be mounted at /srv/disks/data{N}.
        At least one data bay is required.
      '';
      example = [ 2 3 ];
    };
  };

  config = {
    storage.snapraid.parityBays = config.nixos.storage.parityBays;
    storage.snapraid.dataBays = config.nixos.storage.dataBays;
    storage.mergerfs.dataBays = config.nixos.storage.dataBays;
  };
}
