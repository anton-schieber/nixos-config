#!/bin/sh
pushd ~/.dotfiles
home-manager switch -f ./users/anton/home.nix
popd