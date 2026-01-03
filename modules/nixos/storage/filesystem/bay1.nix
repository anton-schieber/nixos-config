#
# Description:
#   Bay 1 filesystem configuration. This module applies consistent mount options to the
#   /srv/disks/bay1 filesystem.
#
# Usage:
#   Import this module from the machine's storage configuration:
#       imports = [
#         ../../modules/nixos/storage/filesystem/bay1.nix
#       ];
#

import ./bay 1
