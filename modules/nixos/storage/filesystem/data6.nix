#
# Description:
#   Data disk 6 filesystem configuration. This module applies consistent mount options to
#   the /srv/disks/data6 filesystem.
#
# Usage:
#   Import this module from the machine's storage configuration:
#       imports = [
#         ../../modules/nixos/storage/filesystem/data6.nix
#       ];
#

import ./data 6
