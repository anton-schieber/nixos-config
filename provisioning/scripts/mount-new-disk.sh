#!/usr/bin/env bash

#
# Description:
#   This script mounts a previously provisioned data disk using disko in mount mode. It
#   does not repartition or format the disk - it only mounts existing filesystems.
#
#   Use this script when you need to remount data disks after boot SSD provisioning
#   during installation, or when mounting disks that have already been provisioned.
#
# Usage:
#   mount-new-disk.sh --disk /dev/disk/by-id/XXXX --bay <1-8> [options]
#
#   Options:
#       --disk <path>  Required. Disk device path (must be a stable by-id path).
#       --bay <1-8>    Required. NAS bay number (must match provisioned label).
#       --yes          Skip interactive confirmation prompt.
#       --dry-run      Dry-run. Print the disko command and exit without mounting.
#       --help         Show usage information.
#
# Notes:
#   - The disk must already be provisioned with the correct bay label.
#   - This script does not modify the disk, it only mounts it.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DISKO_FILE="$REPO_ROOT/provisioning/disko/disk.nix"

#
# Description:
#   Print usage information for the script, including required arguments and example
#   invocations.
#
usage() {
    printf '%s\n' \
        "Usage:" \
        "  mount-new-disk.sh --disk /dev/disk/by-id/XXXX --bay <1-8> [options]" \
        "" \
        "Options:" \
        "  --disk <path>  Required. Disk device path (must be a stable by-id path)." \
        "  --bay <1-8>    Required. NAS bay number (must match provisioned label)." \
        "  --yes          Skip interactive confirmation prompt." \
        "  --dry-run      Dry-run. Print the disko command and exit." \
        "  --help         Show usage information." \
        "" \
        "Examples:" \
        "  provisioning/scripts/mount-new-disk.sh --disk /dev/disk/by-id/XXXX --bay 1"
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
#   Prompt the user for explicit confirmation before mounting.
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

# Create disko mount command
CMD=(
    sudo nix
        --experimental-features "nix-command flakes"
        run github:nix-community/disko
        --
        --mode mount
        --arg disk "{ device = \"${DISK_PATH}\"; bay = ${BAY}; }"
        "$DISKO_FILE"
)

# Display configuration summary
echo "Mounting data disk"
echo "  Repo root  : $REPO_ROOT"
echo "  Disk       : $DISK_PATH"
echo "  Bay        : $BAY (label nas-bay$BAY)"
echo "  Mount path : /mnt/srv/disks/nas-bay$BAY"
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
    confirm "About to mount data disk." || { echo "Aborted."; exit 1; }
fi

# Mount the data disk
echo
echo "Running disko in mount mode..."
"${CMD[@]}"

# Complete!
echo
echo "Data disk mount complete."
