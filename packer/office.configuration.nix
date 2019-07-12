let
  nixpkgs = import ./src/nixpkgs.nix;
in
{config,pkgs,lib,...}:{
  imports = [
  <nixpkgs/nixos/modules/virtualisation/amazon-image.nix>

  ./src/modules/common.nix
  ./src/modules/office.nix
  ] ;
 
  nix.nixPath = ["nixpkgs=${nixpkgs}:nixos-config=/etc/nixos/configuration.nix" ];
  networking.hostName="office.example";
 
  nixpkgs.overlays = [
    (import ./src/overlays/pkgs.nix)
  ];
  _module.args.name = "ace";
  _module.args.nodes = {};
  _module.args.resources = {};
 
  systemd.services.wireguard-wg0.enable = false;
  services.nextcloud.config.adminpass = "SOMEPASSWORD";
  systemd.services.amazon-init.enable = true;

  common = import ./config.virtualbox.nix;
  networking.firewall.allowedTCPPorts = [22];
 
}
