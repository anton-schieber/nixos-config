#
# Description:
#   Bay 4 filesystem configuration. This module applies consistent mount options to the
#   /srv/disks/bay4 filesystem.
#
# Usage:
#   Import this module from the machine's storage configuration:
#       imports = [
#         ../../modules/nixos/storage/filesystem/bay4.nix
#       ];
#

import ./bay { inherit lib; } 4
