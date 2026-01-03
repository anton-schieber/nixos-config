#
# Description:
#   Bay 2 filesystem configuration. This module applies consistent mount options to the
#   /srv/disks/bay2 filesystem.
#
# Usage:
#   Import this module from the machine's storage configuration:
#       imports = [
#         ../../modules/nixos/storage/filesystem/bay2.nix
#       ];
#

import ./bay 2
