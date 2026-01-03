#
# Description:
#   Bay 6 filesystem configuration. This module applies consistent mount options to the
#   /srv/disks/bay6 filesystem.
#
# Usage:
#   Import this module from the machine's storage configuration:
#       imports = [
#         ../../modules/nixos/storage/filesystem/bay6.nix
#       ];
#

import ./bay 6
