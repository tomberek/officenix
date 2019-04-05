{
  common = {
    email = "dev@example.com";
    instances = {
      ace = {
        hostname = "cloud.example.com";
        targetEnv = "virtualbox";
        wg = "10.0.0.1";
        acmeServer = "https://acme-staging-v02.api.letsencrypt.org/directory";
        extraConfig = {
          users.users.root.openssh.authorizedKeys = { keyFiles = [ /home/SOMEUSER/.ssh/id_ecdsa.pub ]; };
        };
      };
      office = {
        hostname = "office.cloud.example.com";
        targetEnv = "virtualbox";
        wg = "10.0.0.2";
        extraConfig = {
          services.nextcloud.config.adminpass = "SOMEPASSWORD";
          users.users.root.openssh.authorizedKeys = { keyFiles = [ /home/SOMEUSER/.ssh/id_ecdsa.pub ]; };
        };
      };
    };
  }
}
