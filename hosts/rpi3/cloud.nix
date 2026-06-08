{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

{
  age.secrets.cloudflare.file = ../../secrets/cloudflare.env.age;

  # services.home-assistant.enable = true;

  services.uptime-kuma = {
    enable = true;
    settings = {
      PORT = "48080";
      UPTIME_KUMA_DB_TYPE = "sqlite";
    };
  };

  services.traefik = {
    enable = true;

    environmentFiles = [ config.age.secrets.cloudflare.path ];
    staticConfigOptions = {
      entryPoints = {
        http = {
          address = ":80";
          http.redirections.entrypoint = {
            to = "https";
            scheme = "https";
          };
        };
        https = {
          address = ":443";
          http.tls.certResolver = "letsencrypt";
        };
      };

      log = {
        level = "DEBUG";
        filePath = "${config.services.traefik.dataDir}/traefik.log";
        format = "json";
      };

      certificatesResolvers.letsencrypt.acme = {
        email = "postmaster@kratochvil-jan.eu"; # dummy mail
        storage = "${config.services.traefik.dataDir}/acme.json";
        dnschallenge.provider = "cloudflare";
      };

      api.dashboard = true;
    };

    dynamicConfigOptions = {
      http.routers = {
        hass = {
          rule = "Host(`hass.kratochvil-jan.eu`)";
          service = "hass";
          entryPoints = [ "https" ];
        };
        uptime-kuma = {
          rule = "Host(`uptime.kratochvil-jan.eu`)";
          service = "uptime-kuma";
          entryPoints = [ "https" ];
        };
        dashboard = {
          rule = "Host(`traefik.kratochvil-jan.eu`)";
          service = "api@internal";
          entryPoints = [ "https" ];
        };
      };

      http.services = {
        hass.loadBalancer.servers = [ { url = "http://localhost:8123"; } ];
        uptime-kuma.loadBalancer.servers = [
          { url = "http://localhost:${toString config.services.uptime-kuma.settings.PORT}"; }
        ];
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      80
      443
      8123
      8787
    ];
  };

}
