# WIP: for a k8s module

  # Kube
  environment.systemPackages = with pkgs; [ 
    kompose kubectl
    policyengine 
  ];
  networking.enableIPv6 = false;

  networking.extraHosts = ''
    127.0.0.1 api.kube
    '';

  services.kubernetes = {
    easyCerts = true;
    addons.dashboard.enable = true;
    roles = ["master" "node"];
    masterAddress = "kube";
    kubelet.seedDockerImages = [

      (pkgs.dockerTools.buildLayeredImage {
        name = "policyengine";
        tag = "latest";
        config = {
          Cmd = [ "${pkgs.policyengine}/bin/cmd" "--help" ];
          WorkingDir = "/data";
          Volumes = {
            "/data" = {};
          };
        };
      })

      (pkgs.dockerTools.buildLayeredImage {
        name = "opa";
        tag = "latest";
        config = {
          Cmd = [ "${pkgs.opa}/bin/opa" "--help" ];
          WorkingDir = "/data";
          Volumes = {
            "/data" = {};
          };
        };
      })

      (pkgs.dockerTools.buildLayeredImage {
        name = "traefik";
        tag = "latest";
        config = {
          Cmd = [ "${pkgs.traefik2}/bin/traefik" "--help" ];
          WorkingDir = "/data";
          Volumes = {
            "/data" = {};
          };
        };
      })
    ];

  };
  services.etcd.enable = true;
  services.dockerRegistry.enable = true;

