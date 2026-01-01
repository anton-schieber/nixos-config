#!/usr/bin/env bash

#
# Description:
#   This script provisions the boot SSD for a NixOS system using the
#   provisioning/disko/boot.nix disko definition. It is a destructive, provisioning-time
#   script and must only be run during initial installation or a full OS reinstall.
#
#   The script wraps the disko invocation with argument parsing, validation, and explicit
#   user confirmation to reduce the risk of accidentally wiping the wrong disk.
#
#   This script is not used during normal system operation and must never be run as
#   part of nixos-rebuild or any automated workflow.
#
# Usage:
#   provision-boot-ssd.sh -d /dev/disk/by-id/nvme-XXXX [options]
#
#   Options:
#       -d <path> Required. Boot SSD device path (must be a stable by-id path).
#       -y Skip interactive confirmation prompt.
#       -n Dry-run. Print the disko command and exit without making changes.
#       -h Show usage information.
# Notes:
#   - The target disk will be irreversibly wiped.
#   - Ensure all non-target disks are disconnected if possible.
#   - After provisioning, run nixos-generate-config and proceed with installation.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DISKO_FILE="$REPO_ROOT/provisioning/disko/boot.nix"

#
# Description:
#   Print usage information for the script, including required arguments, optional flags,
#   and example invocations.
#
usage() {
    printf '%s\n' \
        "Usage:" \
        "  provision-boot-ssd.sh -d /dev/disk/by-id/nvme-XXXX [options]" \
        "" \
        "Options:" \
        "  -d <path>   Required. Boot SSD device path (must be a stable by-id path)." \
        "  -y          Skip interactive confirmation prompt." \
        "  -n          Dry-run. Print the disko command and exit." \
        "  -h          Show usage information." \
        "" \
        "Examples:" \
        "  provisioning/scripts/provision-boot-ssd.sh -d /dev/disk/by-id/nvme-XXXX"
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
YES=0
DRYRUN=0

while getopts ":d:ynh" opt; do
    case "$opt" in
        d) DISK_PATH="$OPTARG" ;;
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

CMD=(
    sudo nix
        --experimental-features "nix-command flakes"
        run github:nix-community/disko --
        --mode disko
        --arg "disk" "{ device = \"${DISK_PATH}\"; }"
        "$DISKO_FILE"
)

echo "Boot SSD provisioning"
echo "  Repo root : $REPO_ROOT"
echo "  Disk      : $DISK_PATH"
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
    confirm "About to provision the boot SSD." || { echo "Aborted."; exit 1; }
fi

# Provision the boot SSD
echo
echo "Running disko..."
"${CMD[@]}"

# Complete!
echo
echo "Boot SSD provisioning complete."
