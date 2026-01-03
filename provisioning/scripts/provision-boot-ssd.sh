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
#   provision-boot-ssd.sh --disk /dev/disk/by-id/nvme-XXXX [options]
#
#   Options:
#       --disk <path>    Required. Boot SSD device path (must be a stable by-id path).
#       --create-home    Create @home subvolume for /home
#       --create-log     Create @log subvolume for /var/log
#       --create-nix     Create @nix subvolume for /nix
#       --create-persist Create @persist subvolume for /persist
#       --yes            Skip interactive confirmation prompt.
#       --dry-run        Dry-run. Print the disko command and exit without making changes.
#       --help           Show usage information.
#
# Notes:
#   - The target disk will be irreversibly wiped.
#   - Ensure all non-target disks are disconnected if possible.
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
        "  provision-boot-ssd.sh --disk /dev/disk/by-id/nvme-XXXX [options]" \
        "" \
        "Options:" \
        "  --disk <path>    Required. Boot SSD device path (must be a stable by-id path)." \
        "  --create-home    Create @home subvolume for /home" \
        "  --create-log     Create @log subvolume for /var/log" \
        "  --create-nix     Create @nix subvolume for /nix" \
        "  --create-persist Create @persist subvolume for /persist" \
        "  --yes            Skip interactive confirmation prompt." \
        "  --dry-run        Dry-run. Print the disko command and exit." \
        "  --help           Show usage information." \
        "" \
        "Examples:" \
        "  provisioning/scripts/provision-boot-ssd.sh --disk /dev/disk/by-id/nvme-XXXX" \
        "  provisioning/scripts/provision-boot-ssd.sh --disk /dev/disk/by-id/nvme-XXXX --create-log"
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
CREATE_HOME=false
CREATE_LOG=false
CREATE_NIX=false
CREATE_PERSIST=false

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --disk)
            [ -n "${2:-}" ] || { usage; die "Option --disk requires an argument."; }
            DISK_PATH="$2"
            shift 2
            ;;
        --create-home)
            CREATE_HOME=true
            shift
            ;;
        --create-log)
            CREATE_LOG=true
            shift
            ;;
        --create-nix)
            CREATE_NIX=true
            shift
            ;;
        --create-persist)
            CREATE_PERSIST=true
            shift
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

# Build subvolumes argument if any subvolume is enabled
SUBVOLUMES_ARG=()
if [ "$CREATE_LOG" = true ] || [ "$CREATE_NIX" = true ] || [ "$CREATE_PERSIST" = true ] ||
        [ "$CREATE_HOME" = true ]; then
    SUBVOLUMES_STR="{ "
    if [ "$CREATE_LOG" = true ]; then
        SUBVOLUMES_STR+="createLog = true; "
    fi
    if [ "$CREATE_NIX" = true ]; then
        SUBVOLUMES_STR+="createNix = true; "
    fi
    if [ "$CREATE_PERSIST" = true ]; then
        SUBVOLUMES_STR+="createPersist = true; "
    fi
    if [ "$CREATE_HOME" = true ]; then
        SUBVOLUMES_STR+="createHome = true; "
    fi
    SUBVOLUMES_STR+="}"
    SUBVOLUMES_ARG=(--arg subvolumes "$SUBVOLUMES_STR")
fi

# Create disko command
CMD=(
    sudo nix
        --experimental-features "nix-command flakes"
        run github:nix-community/disko
        --
        --mode disko
        --arg disk "{ device = \"${DISK_PATH}\"; }"
)
if [ "${#SUBVOLUMES_ARG[@]}" -gt 0 ]; then
    CMD+=("${SUBVOLUMES_ARG[@]}")
fi
CMD+=("$DISKO_FILE")

# Display configuration summary
echo "Boot SSD provisioning"
echo "  Repo root : $REPO_ROOT"
echo "  Disk      : $DISK_PATH"
echo "  Disko file: $DISKO_FILE"
echo "  Subvolumes:"
echo "      @"
if [ "$CREATE_HOME" = true ]; then
    echo "      @home"
fi
if [ "$CREATE_LOG" = true ]; then
    echo "      @log"
fi
if [ "$CREATE_NIX" = true ]; then
    echo "      @nix"
fi
if [ "$CREATE_PERSIST" = true ]; then
    echo "      @persist"
fi

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

# Disable any swap on this device before wiping
echo
echo "Disabling swap on target device..."
sudo swapoff "${DISK_PATH}"* 2>/dev/null || true

# Wipe the disk completely: partition tables and filesystem signatures
echo
echo "Wiping partition table and filesystem signatures..."
sudo sgdisk --zap-all "$DISK_PATH" || die "Failed to zap partition table on $DISK_PATH"
sudo wipefs --all --force "$DISK_PATH" || \
    die "Failed to wipe filesystem signatures on $DISK_PATH"

# Provision the boot SSD
echo
echo "Running disko..."
"${CMD[@]}"

# Complete!
echo
echo "Boot SSD provisioning complete."
