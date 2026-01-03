#
# Description:
#   Data disk 1 filesystem configuration. This module applies consistent mount options to
#   the /srv/disks/data1 filesystem.
#
# Usage:
#   Import this module from the machine's storage configuration:
#       imports = [
#         ../../modules/nixos/storage/filesystem/data1.nix
#       ];
#

import ./data 1
