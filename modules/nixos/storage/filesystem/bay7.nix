#
# Description:
#   Bay 7 filesystem configuration. This module applies consistent mount options to the
#   /srv/disks/bay7 filesystem.
#
# Usage:
#   Import this module from the machine's storage configuration:
#       imports = [
#         ../../modules/nixos/storage/filesystem/bay7.nix
#       ];
#

import ./bay { inherit lib; } 7
