{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

{
  age.secrets.cloudflare.file = ../../secrets/cloudflare.env.age;

  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      home-assistant = {
        image = "ghcr.io/home-assistant/home-assistant:2026.1.1";
        ports = [ "8124:8123" ];
        volumes = [
          "/var/lib/home-assistant:/config"
          "/etc/localtime:/etc/localtime:ro"
        ];
        environment = {
          TZ = "Europe/Prague";
        };
        extraOptions = [
          "--pull=always"
        ];
      };
    };
  };

  services.silverbullet = {
    enable = true;
    listenPort = 8126;
    extraArgs = [ "-L0.0.0.0" ];
  };

  # log in via standard linux user + pw
  services.cockpit = {
    enable = true;
    # plugins = with pkgs; [ cockpit-files ];
    settings = {
      WebService.AllowUnencrypted = true;
      WebService.Origins = lib.mkForce "https://cockpit.kratochvil-jan.eu wss://kratochvil-jan.eu https://localhost:${toString config.services.cockpit.port}";
      WebService.ProtocolHeader = "X-Forwarded-Proto";
      WebService.ForwardedForHeader = "X-Forwarded-Proto";
    };
  };

  services.homepage-dashboard = {
    enable = true;
    allowedHosts = "localhost:${toString config.services.homepage-dashboard.listenPort},kratochvil-jan.eu";
    services = [
      {
        "Services" = [
          {
            "traefik" = {
              href = "http://traefik.kratochvil-jan.eu";
              icon = "traefik.svg";
            };
          }
          {
            "forgejo" = {
              href = "http://git.kratochvil-jan.eu";
              icon = "forgejo.svg";
            };
          }
          {
            "hass" = {
              href = "http://hass.kratochvil-jan.eu";
              icon = "home-assistant.svg";
            };
          }
          {
            "cockpit" = {
              href = "http://cockpit.kratochvil-jan.eu";
              icon = "cockpit.svg";
            };
          }
          {
            "jotty" = {
              href = "http://jotty.kratochvil-jan.eu";
              icon = "jotty.svg";
            };
          }
          {
            "silverbullet" = {
              href = "http://silverbullet.kratochvil-jan.eu";
              icon = "silverbullet.svg";
            };
          }
        ];
      }
    ];
    settings = {
      title = "home cloud";
      color = "white";
      theme = "dark";
      iconStyle = "theme";
      language = "en";
      target = "_self"; # open links in the same tab

      layout = {
        User = {
          style = "row";
          columns = 4;
        };

        Media = {
          style = "row";
          columns = 4;
        };

        Services = {
          style = "row";
          columns = 4;
        };
      };
    };
    widgets = [
      {
        resources = {
          cpu = true;
          disk = "/";
          memory = true;
        };
      }
      {
        search = {
          provider = "duckduckgo";
          target = "_blank";
        };
      }
    ];
  };

  services.forgejo =
    let
      srv = config.services.forgejo.settings.server;
    in
    {
      enable = true;
      database.type = "postgres";
      # Enable support for Git Large File Storage
      lfs.enable = true;
      settings = {
        server = {
          DOMAIN = "git.kratochvil-jan.eu";
          # You need to specify this to remove the port from URLs in the web UI.
          ROOT_URL = "https://${srv.DOMAIN}/";
          HTTP_PORT = 3000;
        };
        # You can temporarily allow registration to create an admin user.
        service.DISABLE_REGISTRATION = true;
        # Add support for actions, based on act: https://github.com/nektos/act
        actions = {
          ENABLED = true;
          DEFAULT_ACTIONS_URL = "github";
        };
        mailer = {
          ENABLED = false;
        };
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
          forwardedHeaders = {
            trustedIPs = [ "0.0.0.0/0" ];
          };
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
        root = {
          rule = "Host(`kratochvil-jan.eu`) && PathPrefix(`/`)";
          service = "homepage";
          entryPoints = [ "https" ];
        };
        git = {
          rule = "Host(`git.kratochvil-jan.eu`) || Host(`forgejo.kratochvil-jan.eu`)";
          service = "git";
          entryPoints = [ "https" ];
        };
        hass = {
          rule = "Host(`hass.kratochvil-jan.eu`)";
          service = "hass";
          entryPoints = [ "https" ];
        };
        hass2 = {
          rule = "Host(`hass2.kratochvil-jan.eu`)";
          service = "hass2";
          entryPoints = [ "https" ];
        };
        cockpit = {
          rule = "Host(`cockpit.kratochvil-jan.eu`)";
          service = "cockpit";
          entryPoints = [ "https" ];
        };
        jotty = {
          rule = "Host(`jotty.kratochvil-jan.eu`)";
          service = "jotty";
          entryPoints = [ "https" ];
        };
        silverbullet = {
          rule = "Host(`silverbullet.kratochvil-jan.eu`)";
          service = "silverbullet";
          entryPoints = [ "https" ];
        };
        dashboard = {
          rule = "Host(`traefik.kratochvil-jan.eu`)";
          service = "api@internal";
          entryPoints = [ "https" ];
        };
      };

      http.services = {
        homepage.loadBalancer.servers = [
          { url = "http://localhost:${toString config.services.homepage-dashboard.listenPort}"; }
        ];
        git.loadBalancer.servers = [
          { url = "http://localhost:${toString config.services.forgejo.settings.server.HTTP_PORT}"; }
        ];
        hass.loadBalancer.servers = [ { url = "http://localhost:8123"; } ];
        hass2.loadBalancer.servers = [ { url = "http://localhost:8124"; } ];
        cockpit.loadBalancer.servers = [
          { url = "http://localhost:${toString config.services.cockpit.port}"; }
        ];
        jotty.loadBalancer.servers = [ { url = "http://localhost:8125"; } ];
        silverbullet.loadBalancer.servers = [ { url = "http://localhost:8126"; } ];
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];
  };

}
