rec{
  defaults = {config,pkgs, name,resources, ...}:{
    common = common_config;
    imports = [ 
      ./modules/common.nix
    ] ++ (if common_config.instances.ace.targetEnv == "ec2" then 
      [<nixpkgs/nixos/modules/virtualisation/amazon-image.nix>] else []);
    deployment = (commonDeployment {inherit common_config name resources;}).deployment;
  };
  common_config = (import <nixpkgs/nixos/lib/eval-config.nix>{
    system = builtins.currentSystem;
    modules = [ ./modules/common.nix <config.nix>];
  }).config.common;

  commonDeployment = {common_config, name, resources} : {
    deployment.keys."wg.priv" = let 
      a = if resources.output != {} then 
      resources.output."wg_key_${name}".value else null;
      in if a == null then {} else {
      text = (builtins.fromJSON a).priv;
    };
    deployment.targetEnv = common_config.instances.ace.targetEnv;
    deployment.ec2 = if common_config.instances."${name}".targetEnv == "ec2" then {
        securityGroups = [ resources.ec2SecurityGroups.office-sg ];
        tags.Project="zerotrust";
        ebsInitialRootDiskSize = 30;
        ebsOptimized = true;
        associatePublicIpAddress = true;
        instanceType = "t3.large";
    } // common_config.instances."${name}".ec2 else {};
    deployment.virtualbox = 
      if common_config.instances."${name}".targetEnv == "virtualbox" then {
        memorySize = 4096; # megabytes
        vcpu = 2; # number of cpus
        headless = true;
      } else {};
  };
}
