#
# Description:
#   Data disk 2 filesystem configuration. This module applies consistent mount options to
#   the /srv/disks/data2 filesystem.
#
# Usage:
#   Import this module from the machine's storage configuration:
#       imports = [
#         ../../modules/nixos/storage/filesystem/data2.nix
#       ];
#

import ./data 2
