#
# Description:
#   Data disk 4 filesystem configuration. This module applies consistent mount options to
#   the /srv/disks/data4 filesystem.
#
# Usage:
#   Import this module from the machine's storage configuration:
#       imports = [
#         ../../modules/nixos/storage/filesystem/data4.nix
#       ];
#

import ./data 4
