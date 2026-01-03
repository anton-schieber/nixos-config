#
# Description:
#   Bay 5 filesystem configuration. This module applies consistent mount options to the
#   /srv/disks/bay5 filesystem.
#
# Usage:
#   Import this module from the machine's storage configuration:
#       imports = [
#         ../../modules/nixos/storage/filesystem/bay5.nix
#       ];
#

import ./bay { inherit lib; } 5
