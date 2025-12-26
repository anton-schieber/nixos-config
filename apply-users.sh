#!/bin/sh
pushd ~/.config/nix
home-manager switch -f ./users/anton/home.nix
popd