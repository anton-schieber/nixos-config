# Provisioning

This directory contains provisioning-time tooling for this repository.

Everything under provisioning/ is intentionally destructive, manually executed, and must
never be invoked as part of normal NixOS operation or nixos-rebuild.  These tools exist to
bootstrap disks and hardware before the system is installed or extended.

Nothing in this directory is imported by NixOS or Home Manager modules.

## Overview

Provisioning is split into two distinct responsibilities:
1. Boot disk provisioning
    - Wipes and initialises the NVMe boot SSD
    - Creates EFI, swap, and btrfs root layout
    - Used during initial installation or full OS reinstall
2. Data disk provisioning
    - Wipes and initialises a single new data disk
    - Formats it as ext4 with label based on NAS bay position (nas-bayN)
    - Used during initial install or when expanding storage capacity

Runtime configuration such as mounting disks, snapRAID, and mergerfs is handled elsewhere
in the repository and is not part of provisioning.

### Safety model

All provisioning tools are designed with the following rules:
- They are run manually and explicitly
- They require stable /dev/disk/by-id paths
- They prompt for confirmation unless explicitly bypassed
- They operate on exactly one disk per invocation
- They must never be imported into machine configurations

You should assume that every provisioning command will irreversibly wipe the target disk.

## Boot SSD provisioning

Boot SSD provisioning uses `provisioning/disko/boot.nix` and is wrapped by the
`provision-boot-ssd.sh` script.

The boot disk always creates a root (`@`) btrfs subvolume. Additional subvolumes for
`/var/log`, `/nix`, `/persist`, and `/home` can be optionally enabled via flags.

This should be run from the repository root.

Steps:
1. Identify the NVMe boot disk by-id
```bash
ls -l /dev/disk/by-id | grep -i nvme
```
2. Provision the boot SSD (note, for a full list of options, run with the `--help` flag)
```bash
# Basic provisioning (root subvolume only)
sudo provisioning/scripts/provision-boot-ssd.sh --disk /dev/disk/by-id/nvme-XXXX

# With optional subvolumes
sudo provisioning/scripts/provision-boot-ssd.sh --disk /dev/disk/by-id/nvme-XXXX --create-log
```

## Data disk provisioning

Data disk provisioning uses `provisioning/disko/disk.nix` and is wrapped by the
`provision-new-disk.sh` script.  They are provisioned one at a time.

This process is intentionally separate from runtime configuration.

Steps:
1. Identify the physical bay numbers and disk serial numbers.
   Open the NAS bay cover and read the serial numbers from the disk labels. Note which
   bay each serial number is in. Bay numbering is a manual process - the operating system
   cannot detect physical bay positions.
2. List all disks with their serial numbers
```bash
lsblk -o NAME,PATH,SERIAL,MODEL,SIZE,TYPE
```
3. Match the serial numbers from step 1 with the output to determine each disk's device
   path (e.g., `/dev/sda`, `/dev/sdb`).
4. For each disk, find its stable by-id path
```bash
ls -l /dev/disk/by-id/ | grep sda
```
   Look for the `ata-` or `nvme-` identifier (not the `-partN` variants). This gives you
   the stable `/dev/disk/by-id/ata-XXXXX` path to use for provisioning.
5. Provision each disk with its corresponding bay number (note, for a full list of
   options, run with the `--help` flag)
```bash
sudo provisioning/scripts/provision-new-disk.sh --disk /dev/disk/by-id/XXXX --bay 1
```

### Mounting provisioned data disks

If it is necessary to mount data disks that have already been provisioned (for example,
after boot SSD provisioning during installation), use the `mount-new-disk.sh` script.

This script uses disko in mount mode, which does not repartition or format - it only
mounts existing filesystems.

Steps:
1. Identify the disk by-id path and bay number (same as provisioning)
2. Mount the disk (note, for a full list of options, run with the `--help` flag)
```bash
sudo provisioning/scripts/mount-new-disk.sh --disk /dev/disk/by-id/XXXX --bay 1
```
3. Repeat for each data disk that needs to be mounted

NOTE: this is only necessary during installation

## Notes

Provisioning does not:
- Configure runtime mounts
- Configure snapRAID
- Configure mergerfs
- Modify machine configuration

Those concerns are handled declaratively in the main NixOS configuration.

Operating notes:
- Always double-check /dev/disk/by-id paths before provisioning.
- If possible, disconnect non-target disks during provisioning.
- Never rely on directory names or mountpoints to identify disks.
- Treat provisioning scripts as write-once tools for each disk.
- Provisioning is rare, destructive, and deliberate by design.
