#!/bin/sh
pushd ~/.config/nix
sudo nixos-rebuild switch -I nixos-config=./system/configuration.nix
popd