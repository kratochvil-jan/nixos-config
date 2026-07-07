{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

let
  domain = "kratochvil-jan.eu";

  services = {
    traefik = {
      storage = "/services/traefik";
      icon = "traefik.svg";
      prefix = "traefik";
      hide-traefik = true;
    };
    hass = {
      port = 8001;
      storage = "/services/hass";
      icon = "home-assistant.svg";
      prefix = "hass";
    };
    silverbullet = {
      port = 8002;
      storage = "/services/silverbullet";
      icon = "silverbullet.svg";
      prefix = "silverbullet";
    };
    homepage = {
      port = 8003;
      storage = "/services/homepage";
      prefix = "";
      hide-homepage = true;
    };
    forgejo = {
      port = 8004;
      storage = "/services/forgejo";
      icon = "forgejo.svg";
      prefix = "git";
    };
  };

  # Convert the services config above into configuration for homepage-dashboard
  homepageServices = builtins.attrValues (
    builtins.mapAttrs (name: cfg: {
      ${name} = {
        href = "http://${cfg.prefix}.${domain}";
        icon = cfg.icon;
      };
    }) (builtins.filterAttrs (_: cfg: !(cfg."hide-homepage" or false)) services)
  );

  # Generate traefik routes
  # i have vibed this

  mkRouter = name: svc: {
    ${name} = {
      rule = "Host(`${svc.prefix}.${domain}`)";
      service = name;
      entryPoints = [ "https" ];
    };
  };

  mkService = name: svc: {
    ${name}.loadBalancer.servers = [
      {
        url = "http://localhost:${toString svc.port}";
      }
    ];
  };

  traefikServices = {
    # filter away items not to auto-populate
    services = builtins.filterAttrs (_: svc: !(svc."hide-traefik" or false)) services;

    generatedRouters = builtins.foldl' (a: b: a // b) { } (
      builtins.attrValues (builtins.mapAttrs mkRouter traefikServices.services)
    );

    generatedServices = builtins.foldl' (a: b: a // b) { } (
      builtins.attrValues (builtins.mapAttrs mkService traefikServices.services)
    );
  };
in
{
  age.secrets.cloudflare.file = ../../secrets/cloudflare.env.age;

  imports = [ ];

  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers.home-assistant = {
    image = "ghcr.io/home-assistant/home-assistant:2026.1.1";
    ports = [ "${toString services.hass.port}:8123" ];
    volumes = [
      "${services.hass.storage}:/config"
      "/etc/localtime:/etc/localtime:ro"
    ];
    environment = {
      TZ = "Europe/Prague";
    };
    extraOptions = [
      "--pull=always"
    ];
  };

  services.silverbullet = {
    enable = true;
    listenPort = services.silverbullet.port;
    extraArgs = [ "-L0.0.0.0" ];
  };

  services.homepage-dashboard = {
    enable = true;
    allowedHosts = "localhost:${toString services.homepage.port},${domain}";
    services = [
      {
        "Services" = homepageServices;
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
          DOMAIN = "${services.forgejo.prefix}.${domain}";
          # You need to specify this to remove the port from URLs in the web UI.
          ROOT_URL = "https://${srv.DOMAIN}/";
          HTTP_PORT = services.forgejo.port;
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
        filePath = "${config.services.traefik.storage}/traefik.log";
        format = "json";
      };

      certificatesResolvers.letsencrypt.acme = {
        email = "postmaster@${domain}"; # dummy mail
        storage = "${config.services.traefik.storage}/acme.json";
        dnschallenge.provider = "cloudflare";
      };

      api.dashboard = true;
    };

    dynamicConfigOptions = {
      http.routers = {
        root = {
          rule = "Host(`${domain}`) && PathPrefix(`/`)";
          service = "homepage";
          entryPoints = [ "https" ];
        };
      }
      // traefikServices.generatedRouters;

      http.services = {
        homepage.loadBalancer.servers = [
          { url = "http://localhost:${toString services.homepage.port}"; }
        ];
      }
      // traefikServices.generatedServices;
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];
  };

}
