#!/usr/bin/env bash

nix run github:nix-community/nixos-anywhere -- \
    --generate-hardware-config nixos-facter ./facter.json \
    --flake .#bart-server \
    --target-host root@78.46.150.107 \
