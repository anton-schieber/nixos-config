#
# Description:
#   Default Home Manager configuration. This module sets up Home Manager to use the system
#   package set and install user packages into user profiles rather than system-wide.
#
# Usage:
#   Import this module from a machine configuration:
#       imports = [
#         ../../modules/home-manager
#       ];
#

{ inputs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  # System package set is used for Home Manager packages
  home-manager.useGlobalPkgs = true;
  # User packages are installed into the user profile instead of system-wide
  home-manager.useUserPackages = true;
}
