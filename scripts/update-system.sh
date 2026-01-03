#!/usr/bin/env bash

#
# Description:
#   This script updates the flake inputs (nixpkgs, home-manager, etc.) by updating
#   the flake.lock file in ~/.config/nix. This is the flake equivalent of 
#   'nix-channel --update'.
#
#   Run this periodically to get the latest package versions from your flake inputs.
#   After updating, rebuild your system with rebuild-system.sh to apply the updates.
#
# Usage:
#   update-system.sh
#
# Examples:
#   scripts/update-system.sh
#

set -euo pipefail

# Use ~/.config/nix as the flake directory
FLAKE_DIR="$HOME/.config/nix"
if [ ! -d "$FLAKE_DIR" ]; then
    echo "ERROR: Flake directory does not exist: $FLAKE_DIR" 1>&2
    exit 1
fi

echo "Updating flake inputs"
echo "  Flake dir  : $FLAKE_DIR"
echo

# Build and execute the nix flake update command
echo "Running nix flake update..."
nix flake update "$FLAKE_DIR"

echo
echo "Flake inputs updated successfully."
echo "Run rebuild-system.sh to apply the updates."
