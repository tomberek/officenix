let
  nixpkgs = import ./src/nixpkgs.nix;
  lib = import (nixpkgs + "/lib");
  builder = import ( nixpkgs + "/nixos/default.nix");
in
  builder {
    configuration = import ./ace.configuration.nix;
  }
