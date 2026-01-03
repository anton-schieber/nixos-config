#
# Description:
#   SnapRAID configuration module for multi-disk data protection. This module configures
#   SnapRAID for managing parity across multiple data disks.
#
#   This module provides a common baseline configuration that can be customized per
#   machine via the nixos.storage.snapraid options. Machine-specific configuration uses a
#   bay-based approach where disks are identified by their physical bay position.
#
# Usage:
#   Import this module from a machine configuration:
#       imports = [
#         ../../modules/nixos/storage/snapraid.nix
#       ];
#   Configure SnapRAID:
#       nixos.storage.snapraid = {
#         parityBays = [ 1 2 ];
#         dataBays = [ 3 4 5 ];
#       };
#
# Notes:
#   - Requires at least one parity bay and one data bay
#   - Disks must be mounted at /srv/disks/data{N} before snapRAID operations
#   - Content files are automatically stored on root filesystem and all data disks
#   - Each parity disk should be at least as large as the largest data disk
#   - Sync runs daily at 1am
#   - Scrub runs weekly on Friday at 2am (8% of array)
#

{ pkgs, lib, config, ... }:

let
  # Generate paths from bay numbers
  parityPaths =
    map (bay: "/srv/disks/data${toString bay}/snapraid.parity")
    config.nixos.storage.snapraid.parityBays;
  dataPaths =
    map (bay: "/srv/disks/data${toString bay}")
    config.nixos.storage.snapraid.dataBays;
  contentPaths =
    [ "/var/snapraid/snapraid.content" ]
    ++ (map (path: "${path}/snapraid.content") dataPaths);

  # Generate snapraid.conf entries
  parityNames =
    lib.imap0 (i: _: if i == 0 then "parity" else "${toString (i + 1)}-parity")
    config.nixos.storage.snapraid.parityBays;
  parityConfig =
    lib.concatStringsSep "\n"
    (lib.zipListsWith (name: path: "${name} ${path}") parityNames parityPaths);
  dataNames =
    lib.genList (i: "d${toString (i + 1)}")
    (builtins.length config.nixos.storage.snapraid.dataBays);
  dataConfig =
    lib.concatStringsSep "\n"
    (lib.zipListsWith (name: path: "data ${name} ${path}") dataNames dataPaths);
  contentConfig =
    lib.concatStringsSep "\n" (map (path: "content ${path}") contentPaths);

  # Main snapraid configuration file
  snapraidConfigurationFile = pkgs.writeText "snapraid.conf" ''
    # Parity files
    ${parityConfig}

    # Content files
    ${contentConfig}

    # Data disks
    ${dataConfig}

    # Exclude hidden files and directories
    exclude *.unrecoverable
    exclude /tmp/
    exclude /lost+found/
    exclude *.!sync
    exclude .AppleDouble
    exclude ._AppleDouble
    exclude .DS_Store
    exclude ._.DS_Store
    exclude .Thumbs.db
    exclude .fseventsd
    exclude .Spotlight-V100
    exclude .TemporaryItems
    exclude .Trashes
    exclude .DocumentRevisions-V100

    # Auto-save state every 500 GiB processed
    autosave 500
  '';
in
{
  imports = [
    ./default.nix
  ];

  options.nixos.storage.snapraid = {
    parityBays = lib.mkOption {
      type = lib.types.listOf lib.types.int;
      description = ''
        List of physical bay numbers containing parity disks.
        Each disk must be mounted at /srv/disks/data{N}.
        Each parity disk must be at least as large as the largest data disk.
        At least one parity bay is required for snapRAID operation. Supports up to 6
        parity disks.
      '';
      example = [ 1 2 ];
    };
    dataBays = lib.mkOption {
      type = lib.types.listOf lib.types.int;
      description = ''
        List of physical bay numbers containing data disks.
        Each disk must be mounted at /srv/disks/data{N}.
        At least one data bay is required for snapRAID operation.
      '';
      example = [ 3 4 5 ];
    };
  };

  config = {
    assertions = [
      {
        assertion = builtins.length config.nixos.storage.snapraid.parityBays >= 1;
        message = "snapRAID requires at least one parity bay.";
      }
      {
        assertion = builtins.length config.nixos.storage.snapraid.parityBays <= 6;
        message = "snapRAID supports a maximum of 6 parity bays.";
      }
      {
        assertion =
          builtins.all (bay: bay > 0) config.nixos.storage.snapraid.parityBays;
        message = "All snapRAID parity bay numbers must be positive integers.";
      }
      {
        assertion = builtins.length config.nixos.storage.snapraid.dataBays >= 1;
        message = "snapRAID requires at least one data bay.";
      }
      {
        assertion =
          builtins.all (bay: bay > 0) config.nixos.storage.snapraid.dataBays;
        message = "All snapRAID data bay numbers must be positive integers.";
      }
      {
        assertion =
          builtins.all (parityBay:
            ! builtins.elem parityBay config.nixos.storage.snapraid.dataBays)
            config.nixos.storage.snapraid.parityBays;
        message = "snapRAID parity bays cannot also be listed as data bays.";
      }
      {
        assertion =
          builtins.length (lib.unique config.nixos.storage.snapraid.parityBays)
          == builtins.length config.nixos.storage.snapraid.parityBays;
        message = "snapRAID parity bays must be unique.";
      }
      {
        assertion =
          builtins.length (lib.unique config.nixos.storage.snapraid.dataBays)
          == builtins.length config.nixos.storage.snapraid.dataBays;
        message = "snapRAID data bays must be unique.";
      }
    ];

    # Install snapRAID package
    environment.systemPackages = [ pkgs.snapraid ];
    # Create content file directory
    systemd.tmpfiles.rules = [
      "d /var/snapraid 0755 root root -"
    ];
    # SnapRAID sync service
    systemd.services.snapraid-sync = {
      description = "SnapRAID sync operation";
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart =
          "${pkgs.snapraid}/bin/snapraid -c ${snapraidConfigurationFile} sync";
        Nice = 19;
        IOSchedulingClass = "idle";
      };
    };
    # SnapRAID sync timer (daily at 1am)
    systemd.timers.snapraid-sync = {
      description = "SnapRAID sync timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* 01:00:00";
        Persistent = true;
        RandomizedDelaySec = "30m";
      };
    };
    # SnapRAID scrub service
    systemd.services.snapraid-scrub = {
      description = "SnapRAID scrub operation";
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart =
          "${pkgs.snapraid}/bin/snapraid"
          + " -c ${snapraidConfigurationFile} scrub -p 8 -o 10";
        Nice = 19;
        IOSchedulingClass = "idle";
      };
    };
    # SnapRAID scrub timer (weekly on Friday at 2am)
    systemd.timers.snapraid-scrub = {
      description = "SnapRAID scrub timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "Fri *-*-* 02:00:00";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
  };
}
