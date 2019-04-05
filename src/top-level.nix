let
  common= import <config.nix>;
  pkgs = import <nixpkgs>{};
  lib = pkgs.lib;
  utils = import ./utils.nix;
  inherit (utils) common_config commonDeployment;

in {
  defaults = utils.defaults;

  # The ACE
  ace = { ... }: lib.recursiveUpdate {
    networking.firewall.allowedTCPPorts = [22 80 443 ];
    imports = [ ./modules/ace.nix ];

  } common_config.instances.ace.extraConfig;

  # A Service
  office = { ... }: lib.recursiveUpdate {
    imports = [ ./modules/office.nix ];

  } common_config.instances.office.extraConfig;

  network.description = "zerotrust-office";
  network.enableRollback = true;

  resources = common_config.resources;
}

