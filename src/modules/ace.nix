{ config, pkgs, lib, ...}:
let
  cfg = config.common;

  inherit (lib) mkOption types;
in 
{
  options = with types; {
    ace.clientCA = mkOption {
      default = {};
      description = "Client CA file for ACE";
      example = {};
      type = either string path;
    };
  };
  config = {
    services.traefik = {
      package = pkgs.traefik2;
      enable = true; # {{{
      configOptions = {
        defaultEntrypoints = ["https"];
        logLevel = "DEBUG";
        acme = {
          email = "${config.common.email}";
          entryPoint = "https";
          storage = "/var/lib/traefik/acme.json";
          caServer = config.common.instances.ace.acmeServer;
          httpChallenge.entryPoint = "http";
          domains = [
            { main = "${config.common.instances.ace.hostname}";
            sans = [ "${config.common.instances.ace.hostname}" "${config.common.instances.office.hostname}" "mattermost.${config.common.instances.ace.hostname}" ]; }
          ];
        };
        file = {};
        entryPoints.http.address = ":80";
        entryPoints.https = {
          address = ":443";
          tls = {
            minVersion = "VersionTLS12";
            cipherSuites = [
              "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"
              "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
              "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305"
              "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305"
              "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
              "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
              "TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256"
              "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256"
            ];

            sniStrict = true;
            certificates = [{
              certFile = ../../secrets/cert.pem;
              keyFile = ../../secrets/key.pem;
            }];
            ClientCA = { 
              files = [ ../../public/all.pem ];
              optional = false;
            };
          };
        };
        frontends = {
          office = {
            passHostHeader = true;
            entryPoints = [ "https"];
            backend = "office";
            auth.forward.address = "http://127.0.0.1:9000";
            routes.test_1.rule = "Host: ${config.common.instances.ace.hostname},${config.common.instances.office.hostname}";
            passTLSClientCert = { # {{{
              pem = true;
              infos = {
                notBefore = true;
                notAfter = true;
                subject = {
                  country = true;
                  domainComponent = true;
                  province = true;
                  locality = true;
                  organization = true;
                  commonName = true;
                  serialNumber = true;
                };
                issuer = {
                  country = true;
                  domainComponent = true;
                  province = true;
                  locality = true;
                  organization = true;
                  commonName = true;
                  serialNumber = true;
                };
              };
            }; # }}}
          };
          mattermost = {
            passHostHeader = true;
            entryPoints = [ "https"];
            backend = "mattermost";
            auth.forward.address = "http://127.0.0.1:9000";
            routes.test_1.rule = "Host: mattermost.${config.common.instances.ace.hostname}";
            passTLSClientCert = { # {{{
              pem = true;
              infos = {
                notBefore = true;
                notAfter = true;
                sans = true;
                subject = {
                  country = true;
                  domainComponent = true;
                  province = true;
                  locality = true;
                  organization = true;
                  commonName = true;
                  serialNumber = true;
                };
                issuer = {
                  country = true;
                  domainComponent = true;
                  province = true;
                  locality = true;
                  organization = true;
                  commonName = true;
                  serialNumber = true;
                };
              };
            }; # }}}
          };
        };
        backends.office = {
          servers.server1.url = "http://${config.common.instances.office.wg}";
        };
        backends.mattermost = {
          servers.server1.url = "http://127.0.0.1:8080";
        };
      };
    }; # }}}

    services.mattermost = {
          enable=true;
          mutableConfig = true;
          listenAddress = ":8080";
          siteName = "ZeroChat Testing";
          siteUrl = "https://mattermost.${config.common.instances.ace.hostname}";
          extraConfig = {
            WebsocketURL = "wss://mattermost.${config.common.instances.ace.hostname}:443";
            AllowCorsFrom= "mattermost.${config.common.instances.ace.hostname}:443";
          };
    };

    systemd.services = {
      policyengine = { # {{{
        enable = true;
        description = "Rules Engine for ACE";
        wantedBy = [ "multi-user.target" ];
        environment = {
          SSOOFF = "1";
          U2FOFF = "1";
        };
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          ExecStart = "${pkgs.policyengine}/bin/cmd serve -a 127.0.0.1 -p 9000 --opa-endpoint http://127.0.0.1:9001/v1/data/ap/acl/authorize";
        };
      }; # }}}
      opa = { # {{{
        enable = true;
        description = "Open policy agent";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          ExecStart = "${pkgs.opa}/bin/opa run -s -a 127.0.0.1:9001 -f json ${ ../opa/policy/user_acl_eval } ${ ../opa/records/acls.json} ${../opa/records/users.json}";
        };
      };
    }; # }}}
    environment.systemPackages = with pkgs; [
      policyengine
      opa
    ];
  };
}
