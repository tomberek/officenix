{config, pkgs, lib, nodes, name, resources, ...}:
let
  cfg = config.common;

  inherit (lib) mkOption types;
in 
  {
  imports = [ <nixpkgs/nixos/modules/profiles/minimal.nix> ];

  options = with types; {
    common.resources = mkOption {
      default = {
        output.wg_key_office.script = ''
          wg genkey | tr -d '\n' | tee $out/privatekey | wg pubkey | tr -d '\n' > $out/publickey
          jq '{pub:$pub,priv:$priv}' --null-input --rawfile pub $out/publickey --rawfile priv $out/privatekey
        '';
        output.wg_key_ace.script = ''
          wg genkey | tr -d '\n' | tee $out/privatekey | wg pubkey | tr -d '\n' > $out/publickey
          jq '{pub:$pub,priv:$priv}' --null-input --rawfile pub $out/publickey --rawfile priv $out/privatekey
        '';
      };
      description = "NixOps resource options. See nixops manual for further info";
      example = {};
      type = nullOr attrs;
    };
    common.email = mkOption {
      default = null;
      description = "Email contact for various things like Let's Encrypt";
      example = "dev@example.com";
      type = nullOr str;
    };
    common.instances = mkOption {
      default = {};
      description = "Instance settings";
      example = {
      };
      type = attrsOf (submodule ({config, ...}:{
        options = {
          hostname = mkOption {
            default = null;
            description = "Hostname to use for Let's Encrypt, ACE, and service";
            example = "example.com";
            type = str;
          };
          wg = mkOption {
            description = "Wiregurad IP for instance";
            type = str;
          };
          acmeServer = mkOption {
            description = "AMCE server";
            default = "https://acme-v02.api.letsencrypt.org/directory";
		    example = "https://acme-staging-v02.api.letsencrypt.org/directory";
            type = str;
          };
          ec2 = mkOption {
            default = {};
            description = "AWS options. See nixops manual for further info";
            example = {
              region = "us-gov-west-1";
              accessKeyId = "AKAISDFJKLSDFSDSDLF";
              ami = "ami-5d24aa3c";
              instanceType = "t2.medium";
              zone = "us-gov-west-1b";
            };
            type = nullOr attrs;
          };
          targetEnv = mkOption {
            description = "Platform to use for this instance.";
            default = "virtualbox";
            example = "virtualbox";
            type = str;
          };
          extraConfig = mkOption {
            default = {};
            description = "NixOS common options. See nixos manual for further info";
            example = {
              users.users.root.openssh.authorizedKeys = {
                keyFiles = [];
              };
            };
            type = nullOr attrs;
          };
          gce = mkOption {
            default = {};
            description = "GCE options. See nixops manual for further info";
            example = {
              headless = true;
              vcpu = 2;
              memorySize = 1024;
            };
            type = nullOr attrs;
          };
          virtualbox = mkOption {
            default = {};
            description = "Virtualbox options. See nixops manual for further info";
            example = {
              headless = true;
              vcpu = 2;
              memorySize = 2048;
            };
            type = nullOr attrs;
          };
        };
      }));
    };
  };
  config = let
    routable_ip = n:
      let  res = builtins.tryEval n.config.networking.publicIPv4;
           res2 = builtins.tryEval n.config.networking.privateIPv4;
      in if res.success && res.value != null then res.value else
         if res2.success && res2.value != null then res2.value else "240.0.0.1";
    in
    {
    system.nixos.label = 
        builtins.readFile (<nixpkgs/.git-revision>);

    networking.extraHosts = with config.common.instances; ''
      ${office.wg} ${office.hostname}
      ${ace.wg} ${ace.hostname}
    '';

    boot.extraModulePackages = [ config.boot.kernelPackages.wireguard ];
    networking.firewall.allowedUDPPorts = [ 51820 ];

    systemd.services.wireguard-wg0.after = [ "wg.priv-key.service" ];
    networking.wireguard.interfaces = {
      wg0 = {
        ips = [ "${cfg.instances.${name}.wg}/18" ];
        listenPort = 51820;
        privateKeyFile = "/run/keys/wg.priv";
        peers = lib.mapAttrsToList (k: v: {
          publicKey = "'${(builtins.fromJSON (resources.output."wg_key_${k}".value)).pub}'";
          allowedIPs = [ "${cfg.instances.${k}.wg}/32"];
          endpoint = "${if nodes?${k} then routable_ip nodes.${k} else "240.0.0.1"}:51820";
        }) nodes;
      };
    };
    

    nixpkgs.overlays = [ 
      (import ../overlays/pkgs.nix)
    ];

    networking.firewall.allowedTCPPorts = [22];
    networking.firewall.interfaces."docker0".allowedTCPPorts = [ 80 443 ];
    networking.firewall.interfaces."wg0".allowedTCPPorts = [ 80 443 ];
    systemd.additionalUpstreamSystemUnits = [ 
      "proc-sys-fs-binfmt_misc.automount"
      "proc-sys-fs-binfmt_misc.mount"
    ];

    security.pam.loginLimits = [{
      domain = "*";
      type = "hard";
      item = "nofile";
      value = "1048576";
    }];
    
  };
}
