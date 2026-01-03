#!/usr/bin/env bash

#
# Description:
#   This script rebuilds the NixOS system configuration using nixos-rebuild switch.
#   It can operate in two modes:
#     - Production mode: Uses the GitHub flake reference (default)
#     - Development mode: Uses the local flake in ~/.config/nix
#
# Usage:
#   apply-system.sh [options]
#
#   Options:
#       --machine <name>  Required. Machine name to rebuild (e.g., pergamon).
#       --development     Use local flake instead of GitHub.
#       --dry-run         Dry-run. Print the rebuild command and exit.
#       --help            Show usage information.
#
# Examples:
#   scripts/apply-system.sh --machine pergamon
#   scripts/apply-system.sh --machine pergamon --development
#

set -euo pipefail

#
# Description:
#   Print usage information for the script.
#
usage() {
    printf '%s\n' \
        "Usage:" \
        "  apply-system.sh --machine <name> [options]" \
        "" \
        "Options:" \
        "  --machine <name>  Required. Machine name (flake target)." \
        "  --development     Use local flake in ~/.config/nix instead of GitHub." \
        "  --dry-run         Dry-run. Print the rebuild command and exit." \
        "  --help            Show usage information." \
        "" \
        "Examples:" \
        "  scripts/apply-system.sh --machine pergamon" \
        "  scripts/apply-system.sh --machine pergamon --development"
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

MACHINE=""
DEVELOPMENT=0
DRYRUN=0

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --machine)
            [ -n "${2:-}" ] || { usage; die "Option --machine requires an argument."; }
            MACHINE="$2"
            shift 2
            ;;
        --development)
            DEVELOPMENT=1
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
if [ -z "$MACHINE" ]; then
    usage
    die "Missing required --machine <name>."
fi

# Build the nixos-rebuild command
if [ "$DEVELOPMENT" -eq 1 ]; then
    # Development mode: use local flake
    LOCAL_FLAKE="$HOME/.config/nix"
    if [ ! -d "$LOCAL_FLAKE" ]; then
        die "Local flake directory does not exist: $LOCAL_FLAKE"
    fi
    FLAKE_REF="${LOCAL_FLAKE}#${MACHINE}"
    echo "Rebuilding system (development mode)"
    echo "  Machine    : $MACHINE"
    echo "  Flake      : $FLAKE_REF"
else
    # Production mode: use GitHub flake
    FLAKE_REF="github:anton-schieber/nix-config#${MACHINE}"
    echo "Rebuilding system (production mode)"
    echo "  Machine    : $MACHINE"
    echo "  Flake      : $FLAKE_REF"
fi

CMD=(
    sudo nixos-rebuild switch --flake "$FLAKE_REF"
)

# Dry-run: print the command and exit
if [ "$DRYRUN" -eq 1 ]; then
    echo
    echo "Dry-run command:"
    printf "%q " "${CMD[@]}"
    echo
    exit 0
fi

# Execute the rebuild
echo
echo "Running nixos-rebuild..."
"${CMD[@]}"

echo
echo "System rebuild complete."