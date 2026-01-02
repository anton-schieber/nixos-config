#!/usr/bin/env bash

#
# Description:
#   This script provisions a single new data disk for later use in the snapRAID + mergerfs
#   storage stack using the provisioning/disko/disk.nix disko definition.
#
#   The script is intentionally destructive and is designed to be run manually, exactly
#   once per new disk. It performs argument validation, optional bay labeling, and
#   explicit confirmation before invoking disko.
#
#   This script does not configure runtime mounts, snapRAID, or mergerfs. Those steps must
#   be performed separately in the machine storage configuration after provisioning.
#
# Usage:
#   provision-new-disk.sh -d /dev/disk/by-id/XXXX [options]
#
#   Options:
#       -d <path> Required. New disk device path (must be a stable by-id path).
#       -b <1-8> Optional. NAS bay number used to label the filesystem (nas-bayN).
#       -y Skip interactive confirmation prompt.
#       -n Dry-run. Print the disko command and exit without making changes.
#       -h Show usage information.
#
# Notes:
#   - The target disk will be irreversibly wiped.
#   - The filesystem is mounted temporarily at /mnt/provision during provisioning.
#   - Record the resulting filesystem UUID and add it to runtime storage configuration.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DISKO_FILE="$REPO_ROOT/provisioning/disko/disk.nix"

#
# Description:
#   Print usage information for the script, including required arguments, optional flags,
#   and example invocations.
#
usage() {
    printf '%s\n' \
        "Usage:" \
        "  provision-new-disk.sh -d /dev/disk/by-id/XXXX [options]" \
        "" \
        "Options:" \
        "  -d <path>   Required. New disk device path (must be a stable by-id path)." \
        "  -b <1-8>    Optional. NAS bay number used to label the filesystem (nas-bayN)." \
        "  -y          Skip interactive confirmation prompt." \
        "  -n          Dry-run. Print the disko command and exit." \
        "  -h          Show usage information." \
        "" \
        "Examples:" \
        "  provisioning/scripts/provision-new-disk.sh -d /dev/disk/by-id/XXXX" \
        "  provisioning/scripts/provision-new-disk.sh -d /dev/disk/by-id/XXXX -b 3"
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

while getopts ":d:b:ynh" opt; do
    case "$opt" in
        d) DISK_PATH="$OPTARG" ;;
        b) BAY="$OPTARG" ;;
        y) YES=1 ;;
        n) DRYRUN=1 ;;
        h) usage; exit 0 ;;
        \?) usage; die "Unknown option: -$OPTARG" ;;
        :) usage; die "Option -$OPTARG requires an argument." ;;
    esac
done
shift $((OPTIND - 1))

[ -n "$DISK_PATH" ] || { usage; die "Missing required -d <path>."; }
[ -e "$DISK_PATH" ] || die "Device does not exist: $DISK_PATH"
[ -f "$DISKO_FILE" ] || die "Missing disko file: $DISKO_FILE"

if [ -n "$BAY" ]; then
    case "$BAY" in
        [1-8]) ;;
        *) usage; die "Invalid bay '$BAY'. Must be an integer 1-8." ;;
    esac
fi

if [ -n "$BAY" ]; then
    DISK_ARG="{ device = \"${DISK_PATH}\"; bay = ${BAY}; }"
else
    DISK_ARG="{ device = \"${DISK_PATH}\"; }"
fi

CMD=(
    sudo nix
        --experimental-features "nix-command flakes"
        run github:nix-community/disko --
        --mode disko
        --arg "disk" "$DISK_ARG"
        "$DISKO_FILE"
)

echo "New data disk provisioning"
echo "  Repo root : $REPO_ROOT"
echo "  Disk      : $DISK_PATH"
if [ -n "$BAY" ]; then
    echo "  Bay       : $BAY (label nas-bay$BAY)"
else
    echo "  Bay       : (none, no label)"
fi
echo "  Disko file: $DISKO_FILE"

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

# Provision the new data disk
echo
echo "Running disko..."
"${CMD[@]}"

# Complete!
echo
echo "Data disk provisioning complete."
echo "Next steps:"
echo "  - lsblk -f"
echo "  - Record the new filesystem UUID"
echo "  - Add it to your runtime mounts module"
