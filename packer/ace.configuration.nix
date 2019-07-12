let
  nixpkgs = import ./src/nixpkgs.nix;
in
{config,pkgs,lib,...}:{
  imports = [
  #<nixpkgs/nixos/modules/virtualisation/amazon-image.nix>
  <nixpkgs/nixos/modules/virtualisation/virtualbox-image.nix>
  #./hardware-configuration.nix
  ./src/modules/common.nix
  ./src/modules/ace.nix
  ] ;
 
  nix.nixPath = ["nixpkgs=${nixpkgs}:nixos-config=/etc/nixos/configuration.nix" ];
  networking.hostName="ace.example";
 
  nixpkgs.overlays = [
    (import ./src/overlays/pkgs.nix)
  ];
  _module.args.name = "ace";
  _module.args.nodes = {};
  _module.args.resources = {};
 
  # default services to off
  systemd.services.wireguard-wg0.enable = false;
  systemd.services.policyengine.enable = lib.mkForce false;
  systemd.services.amazon-init.enable = true;

  common = import ./config.virtualbox.nix;
  networking.firewall.allowedTCPPorts = [22];
 
}
