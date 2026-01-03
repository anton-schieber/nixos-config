#
# Description:
#   Bay 3 filesystem configuration. This module applies consistent mount options to the
#   /srv/disks/bay3 filesystem.
#
# Usage:
#   Import this module from the machine's storage configuration:
#       imports = [
#         ../../modules/nixos/storage/filesystem/bay3.nix
#       ];
#

import ./bay { inherit lib; } 3
