#
# Description:
#   VS Code remote development compatibility configuration. This module enables nix-ld
#   with common runtime libraries needed for VS Code Server.
#
# Usage:
#   Import this module from a machine configuration:
#       imports = [
#         ../../modules/nixos/compatibility/vscode.nix
#       ];
#

{ pkgs, lib, ... }:

{
  imports = [
    ./default.nix
  ];

  # Provide common runtime libraries needed by VS Code Server
  programs.nix-ld.libraries = lib.mkAfter (with pkgs; [
    openssl
    zlib
    curl
  ]);
}

