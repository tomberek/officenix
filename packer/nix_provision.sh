#!/usr/bin/env bash
set -xe
cd /etc/nixos
nix-channel --remove nixos
nix-channel --add https://nixos.org/channels/nixos-19.03 nixos
nix-channel --update nixos
export NIX_PATH=nixpkgs=$(nix-build src/nixpkgs.nix):nixos-config=/etc/nixos/configuration.nix
nixos-rebuild switch
nix-collect-garbage -d
history -c
