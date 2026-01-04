#!/usr/bin/env bash

#
# Description:
#   This script provisions a single new data disk for later use in the snapRAID + mergerfs
#   storage stack using the provisioning/disko/data.nix disko definition.
#
#   The script is intentionally destructive and is designed to be run manually, exactly
#   once per new disk. It performs argument validation, bay labeling, and explicit
#   confirmation before invoking disko.
#
#   This script does not configure runtime mounts, snapRAID, or mergerfs. Those steps must
#   be performed separately in the machine storage configuration after provisioning.
#
# Usage:
#   provision-data-disk.sh --disk /dev/disk/by-id/XXXX --bay <1-8> [options]
#
#   Options:
#       --disk <path>  Required. New disk device path (must be a stable by-id path).
#       --bay <1-8>    Required. Bay number used to label the filesystem (dataN).
#       --yes          Skip interactive confirmation prompt.
#       --dry-run      Dry-run. Print the disko command and exit without making changes.
#       --help         Show usage information.
#
# Notes:
#   - The target disk will be irreversibly wiped.
#   - Ensure all non-target disks are disconnected if possible.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DISKO_FILE="$REPO_ROOT/provisioning/disko/data.nix"

#
# Description:
#   Print usage information for the script, including required arguments, optional flags,
#   and example invocations.
#
usage() {
    printf '%s\n' \
        "Usage:" \
        "  provision-data-disk.sh --disk /dev/disk/by-id/XXXX --bay <1-8> [options]" \
        "" \
        "Options:" \
        "  --disk <path>  Required. New disk device path (must be a stable by-id path)." \
        "  --bay <1-8>    Required. Bay number (filesystem label: dataN)." \
        "  --yes          Skip interactive confirmation prompt." \
        "  --dry-run      Dry-run. Print the disko command and exit." \
        "  --help         Show usage information." \
        "" \
        "Examples:" \
        "  provisioning/scripts/provision-data-disk.sh --disk /dev/disk/by-id/XXXX --bay 3"
    exit 1
}

#
# Description:
#   Print an error message to stderr and terminate the script.
#
# Arguments:
#   $1 Error message to display.
#
die() {
    echo "ERROR: $*" 1>&2
    exit 1
}

#
# Description:
#   Prompt the user for explicit confirmation before performing a destructive operation.
#
# Arguments:
#   $1 Short description of the action being confirmed.
#
# Returns:
#   0 if the user confirmed, 1 otherwise.
#
confirm() {
    local prompt="$1"
    local ans=""

    echo
    echo "$prompt"
    echo "THIS WILL IRREVERSIBLY WIPE THE TARGET DISK."
    echo
    read -r -p "Type 'YES' to continue: " ans

    [ "$ans" = "YES" ]
}

DISK_PATH=""
BAY=""
YES=0
DRYRUN=0

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --disk)
            [ -n "${2:-}" ] || { usage; die "Option --disk requires an argument."; }
            DISK_PATH="$2"
            shift 2
            ;;
        --bay)
            [ -n "${2:-}" ] || { usage; die "Option --bay requires an argument."; }
            BAY="$2"
            shift 2
            ;;
        --yes)
            YES=1
            shift
            ;;
        --dry-run)
            DRYRUN=1
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            usage
            die "Unknown option: $1"
            ;;
    esac
done

# Validate required arguments
if [ -z "$DISK_PATH" ]; then
    usage
    die "Missing required --disk <path>."
fi
if [ ! -e "$DISK_PATH" ]; then
    die "Device does not exist: $DISK_PATH"
fi
if [ ! -f "$DISKO_FILE" ]; then
    die "Missing disko file: $DISKO_FILE"
fi
if [ -z "$BAY" ]; then
    usage
    die "Missing required --bay <1-8>."
fi
case "$BAY" in
    [1-8]) ;;
    *) usage; die "Invalid bay '$BAY'. Must be an integer 1-8." ;;
esac

# Check if disk or any of its partitions are mounted
REAL_DISK_PATH=$(realpath "$DISK_PATH")
MOUNTED_PARTS=$(lsblk -n -o MOUNTPOINT "${REAL_DISK_PATH}" | grep -v '^$' || true)
if [ -n "$MOUNTED_PARTS" ]; then
    echo "ERROR: Disk or its partitions are currently mounted:" >&2
    lsblk -o NAME,MOUNTPOINT,FSTYPE "${REAL_DISK_PATH}" >&2
    echo "" >&2
    echo "Unmount all partitions before provisioning:" >&2
    echo "$MOUNTED_PARTS" | while read -r mnt; do
        echo "  sudo umount $mnt" >&2
    done
    exit 1
fi

MOUNT_POINT="/srv/disks/data${BAY}"
MNT_MOUNT_POINT="/mnt${MOUNT_POINT}"

# Create commands
CMD=(
    sudo nix
        --experimental-features "nix-command flakes"
        run github:nix-community/disko
        --
        --mode disko
        --arg disk "{ device = \"${DISK_PATH}\"; bay = ${BAY}; }"
        "$DISKO_FILE"
)
UMOUNT_CMD=(
    sudo umount "${MNT_MOUNT_POINT}"
)
MOUNT_CMD=(
    sudo nix
        --experimental-features "nix-command flakes"
        run github:nix-community/disko
        --
        --mode mount
        --arg disk "{ device = \"${DISK_PATH}\"; bay = ${BAY}; }"
        "$DISKO_FILE"
)

# Display configuration summary
echo "New data disk provisioning"
echo "  Repo root  : $REPO_ROOT"
echo "  Disk       : $DISK_PATH"
echo "  Bay        : $BAY (label data$BAY)"
echo "  Disko file : $DISKO_FILE"

# Dry-run: print the command and exit
if [ "$DRYRUN" -eq 1 ]; then
    echo
    echo "Dry-run command:"
    printf "%q " "${CMD[@]}"
    echo
    exit 0
fi

# Prompt for confirmation
if [ "$YES" -ne 1 ]; then
    confirm "About to provision a new data disk." || { echo "Aborted."; exit 1; }
fi

# Wipe the disk completely: partition tables and filesystem signatures
echo
echo "Wiping partition table and filesystem signatures..."
sudo sgdisk --zap-all "$DISK_PATH" || die "Failed to zap partition table on $DISK_PATH"
sudo wipefs --all --force "$DISK_PATH" || \
    die "Failed to wipe filesystem signatures on $DISK_PATH"

# Provision the new data disk
echo
echo "Running disko..."
"${CMD[@]}"

# Unmount from /mnt
echo
echo "Unmounting from ${MNT_MOUNT_POINT}..."
"${UMOUNT_CMD[@]}" || die "Failed to unmount ${MNT_MOUNT_POINT}"

# Remount at actual location using disko mount mode
echo "Mounting at ${MOUNT_POINT} using disko mount mode..."
"${MOUNT_CMD[@]}" || die "Failed to mount at ${MOUNT_POINT}"

# Complete!
echo
echo "Data disk provisioning complete."
echo "  Mounted at: ${MOUNT_POINT}"
