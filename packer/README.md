# Local build
NIX_PATH=nixpkgs=$(nix-build src/nixpkgs.nix) nix-build -A config.system.build.toplevel

# Local vm build
First switch which virtualization is imported (look at `imports`) to use virtualbox-image.nix

NIX_PATH=nixpkgs=$(nix-build src/nixpkgs.nix) nix-build -A config.system.build.virtualBoxOVA

# deploy with nix-delegate
NIX_PATH=nixpkgs=$(nix-store -r --quiet $(nix-instantiate ./src/nixpkgs.nix --quiet)):nixos-config=nixos/configuration.nix nix-delegate --host root@192.168.99.115 --x86_64-linux "nix-build '<nixpkgs/nixos>' -A system" --show-trace

# nix-deploy
nix-deploy system --to root@192.168.99.100 --noSign --path $(readlink ./result)

