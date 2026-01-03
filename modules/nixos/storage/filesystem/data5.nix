#
# Description:
#   Data disk 5 filesystem configuration. This module applies consistent mount options to
#   the /srv/disks/data5 filesystem.
#
# Usage:
#   Import this module from the machine's storage configuration:
#       imports = [
#         ../../modules/nixos/storage/filesystem/data5.nix
#       ];
#

import ./data 5
