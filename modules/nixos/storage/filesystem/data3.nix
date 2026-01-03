#
# Description:
#   Data disk 3 filesystem configuration. This module applies consistent mount options to
#   the /srv/disks/data3 filesystem.
#
# Usage:
#   Import this module from the machine's storage configuration:
#       imports = [
#         ../../modules/nixos/storage/filesystem/data3.nix
#       ];
#

import ./data 3
