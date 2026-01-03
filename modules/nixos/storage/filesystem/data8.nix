#
# Description:
#   Data disk 8 filesystem configuration. This module applies consistent mount options to
#   the /srv/disks/data8 filesystem.
#
# Usage:
#   Import this module from the machine's storage configuration:
#       imports = [
#         ../../modules/nixos/storage/filesystem/data8.nix
#       ];
#

import ./data 8
