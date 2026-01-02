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
    - Formats it as ext4
    - Optionally labels it based on NAS bay position
    - Used when expanding storage capacity

Runtime configuration such as mounting disks, snapRAID, and mergerfs is handled elsewhere
in the repository and is not part of provisioning.

### Safety model

All provisioning tools are designed with the following rules:
- They are run manually and explicitly
- They require stable /dev/disk/by-id paths
- They prompt for confirmation unless explicitly bypassed
- They operate on exactly one disk per invocation
- They must never be imported into host configurations

You should assume that every provisioning command will irreversibly wipe the target disk.

## Boot SSD provisioning

Boot SSD provisioning uses `provisioning/disko/boot.nix` and is wrapped by the
`provision-boot-ssd.sh` script.

This should be run from the repository root.

Steps:
1. Identify the NVMe boot disk by-id
    ```bash
    ls -l /dev/disk/by-id | grep -i nvme
    ```
2. Provision the boot SSD (note, for a full list of options, run with the `-h` flag)
    ```bash
    sudo provisioning/scripts/provision-boot-ssd.sh -d /dev/disk/by-id/nvme-XXXX
    ```
3. Generate hardware configuration (note, after the boot disk is provisioned it is mounted
   under `/mnt`):
    ```bash
    sudo nixos-generate-config --root /mnt
    ```
4. Copy the generated hardware configuration into the appropriate host directory and
   proceed with nixos-install using the flake output.

## Data disk provisioning

Data disk provisioning uses `provisioning/disko/disk.nix` and is wrapped by the
`provision-new-disk.sh` script.  They are provisioned one at a time.

This process is intentionally separate from runtime configuration.

Steps:
1. (Optional) Determine the physical NAS bay number.  Bay numbers are a human convention.
   The operating system cannot reliably detect chassis bay positions. If you want the
   filesystem labelled based on bay position, you must provide it explicitly.  This is
   recommended, but to do so requires each disk to connected one after the other to ensure
   correct mapping
2. Identify the new disk by-id
    ```bash
    ls -l /dev/disk/by-id | grep -E "ata-|nvme-"
    ```
3. Provision the disk (note, for a full list of options, run with the `-h` flag)
    ```bash
    sudo provisioning/scripts/provision-new-disk.sh -d /dev/disk/by-id/XXXX -b 1
    ```
4. Record the filesystem UUID
    ```bash
    lsblk -f
    ```
5. Add the disk to runtime configuration (`hosts/<name>/storage.nix`)
6. Update snapRAID and mergerfs configuration as required and rebuild the system.

## Notes

Provisioning does not:
- Configure runtime mounts
- Configure snapRAID
- Configure mergerfs
- Modify host configuration
- Persist any state in hardware-configuration.nix beyond the boot disk

Those concerns are handled declaratively in the main NixOS configuration.

Operating notes:
- Always double-check /dev/disk/by-id paths before provisioning.
- If possible, disconnect non-target disks during provisioning.
- Never rely on directory names or mountpoints to identify disks.
- Treat provisioning scripts as write-once tools for each disk.
- Provisioning is rare, destructive, and deliberate by design.
