{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

let
  getUser = name: config.systemd.services.${name}.serviceConfig.User or "root";
  getGroup = name: config.systemd.services.${name}.serviceConfig.Group or "root";

  domain = import ../domain.nix;

  dataDir = "/var/lib/backed-services";

  stripDir = dir: lib.removePrefix "/var/lib/" dir;

  services = {
    traefik = {
      storage = "${dataDir}/traefik";
      icon = "traefik.svg";
      prefix = "traefik";
      hideTraefik = true;
      user = getUser "traefik";
      group = getGroup "traefik";
    };
    hass = {
      port = 8001;
      storage = "${dataDir}/home-assistant";
      createFolder = true;
      icon = "home-assistant.svg";
      prefix = "hass";
      user = "root";
      group = "root";
    };
    silverbullet = {
      port = 8002;
      storage = "${dataDir}/silverbullet";
      createFolder = true;
      icon = "markdown.svg";
      prefix = "silverbullet";
      user = getUser "silverbullet";
      group = getGroup "silverbullet";
    };
    homepage = {
      port = 8003;
      # no dynamic storage - only static configs from nix
      # storage = "${dataDir}/homepage";
      prefix = "";
      hideHomepage = true;
      hideTraefik = true;
      user = "homepage"; # getUser "homepage-dashboard";
      group = getGroup "homepage-dashboard";
    };
    forgejo = {
      port = 8004;
      # forgejo has custom tmpfiles rules to create appropriate paths
      storage = "${dataDir}/forgejo";
      icon = "forgejo.svg";
      prefix = "git";
      user = getUser "forgejo";
      group = getGroup "forgejo";
    };
    vaultwarden = {
      port = 8005;
      storage = "${dataDir}/vaultwarden";
      createFolder = true;
      icon = "vaultwarden.svg";
      prefix = "vaultwarden";
      user = getUser "vaultwarden";
      group = getGroup "vaultwarden";
    };
    immich = {
      port = 8006;
      redisPort = 8007;
      storage = "${dataDir}/immich";
      createFolder = true;
      icon = "immich.svg";
      prefix = "immich";
      user = getUser "immich";
      group = getGroup "immich";
    };
    postgresql = {
      storage = "${dataDir}/postgresql/${config.services.postgresql.package.psqlSchema}";
      storagePermission = 0700;
      createFolder = true;
      hideTraefik = true;
      hideHomepage = true;
      user = "postgres";
      group = "postgres";
    };
    jellyfin = {
      port = 8096; # HTTP. looks like i cant change port of jellyfin
      discoveryPort = 7359; # for UDP network discovery
      dlnaPort = 1900; # for DLNA streaming
      # httpsPort = lib.mkDefault 8920; # unused, it's behind reverse proxy
      storage = "${dataDir}/jellyfin";
      createFolder = true;
      icon = "jellyfin.svg";
      prefix = "jellyfin";
      user = getUser "jellyfin";
      group = getGroup "jellyfin";
    };
    paperless = {
      port = 8008;
      storage = "${dataDir}/paperless";
      createFolder = true;
      icon = "paperless.svg";
      prefix = "paperless";
      user = getUser "paperless";
      group = getGroup "paperless";
    };
    adguard = {
      port = 8009;
      storage = "${dataDir}/adguard";
      createFolder = true;
      icon = "adguard.svg";
      prefix = "adguard";
      user = getUser "adguard";
      group = getGroup "adguard";
    };
  };

  # Convert the services config above into configuration for homepage-dashboard
  homepageServices = builtins.attrValues (
    builtins.mapAttrs (name: cfg: {
      ${name} = {
        href = "http://${cfg.prefix}.${domain}";
        icon = cfg.icon;
      };
    }) (lib.filterAttrs (n: v: !(v.hideHomepage or false)) services)
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
    services = lib.filterAttrs (_: svc: !(svc.hideTraefik or false)) services;

    generatedRouters = builtins.foldl' (a: b: a // b) { } (
      builtins.attrValues (builtins.mapAttrs mkRouter traefikServices.services)
    );

    generatedServices = builtins.foldl' (a: b: a // b) { } (
      builtins.attrValues (builtins.mapAttrs mkService traefikServices.services)
    );
  };

  # systemd tmpfiles rules to create respective service directories
  tmpfilesRules = [
    "d '${dataDir}' 0755 root root -"
  ]
  ++ builtins.concatLists (
    builtins.attrValues (
      builtins.mapAttrs (
        _: svc:
        if svc ? createFolder && svc.createFolder == true then
          [
            "d '${svc.storage}' ${toString svc.storagePermission or "0755"} ${svc.user} ${svc.group} -"
          ]
        else
          [ ]
      ) services
    )
  );
in
{
  age.secrets.cloudflare.file = ../../secrets/cloudflare.env.age;
  age.secrets.silverbullet-env.file = ../../secrets/silverbullet.env.age;
  age.secrets.paperless-env.file = ../../secrets/paperless.env.age;

  systemd.tmpfiles.rules = tmpfilesRules;

  imports = [ ];

  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers.home-assistant = {
    image = "ghcr.io/home-assistant/home-assistant:2026.7.2";
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
    spaceDir = services.silverbullet.storage;
    extraArgs = [ "-L0.0.0.0" ];
    envFile = config.age.secrets.silverbullet-env.path;
  };

  systemd.services.homepage-dashboard.environment = {
    # HOMEPAGE_CONFIG_DIR = lib.mkForce services.homepage.storage;
    # NIXPKGS_HOMEPAGE_CACHE_DIR = "/var/cache/homepage-dashboard";
  };
  services.homepage-dashboard = {
    enable = true;
    listenPort = services.homepage.port;
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
      database.type = "sqlite3";
      # Enable support for Git Large File Storage
      lfs.enable = true;
      stateDir = services.forgejo.storage;
      settings = {
        server = {
          DOMAIN = "${services.forgejo.prefix}.${domain}";
          # You need to specify this to remove the port from URLs in the web UI.
          ROOT_URL = "https://${srv.DOMAIN}/";
          HTTP_PORT = services.forgejo.port;
        };
        # You can temporarily allow registration to create an admin user.
        # service.DISABLE_REGISTRATION = true;
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
    dataDir = services.traefik.storage;

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
        filePath = "${services.traefik.storage}/traefik.log";
        format = "json";
      };

      certificatesResolvers.letsencrypt.acme = {
        email = "postmaster@${domain}"; # dummy mail
        storage = "${services.traefik.storage}/acme.json";
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
        # dashboard
        traefik = {
          rule = "Host(`${services.traefik.prefix}.${domain}`)";
          service = "api@internal";
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

  systemd.services.vaultwarden = {
    environment.ROCKET_PORT = (toString services.vaultwarden.port);
    serviceConfig.StateDirectory = lib.mkForce (stripDir services.vaultwarden.storage);
  };
  services.vaultwarden = {
    enable = true;
    domain = "${domain}";
    config.DATA_FOLDER = lib.mkForce services.vaultwarden.storage;
  };

  systemd.services.immich-server.serviceConfig = {
    StateDirectory = lib.mkForce (stripDir services.immich.storage);
  };
  users.users.immich.extraGroups = [
    "video"
    "render"
  ];

  services.immich = {
    enable = true;
    accelerationDevices = [
      "/dev/dri/renderD128"
    ];
    port = services.immich.port;
    settings = null; # configuration is done dynamically via data - to allow config from web
    mediaLocation = services.immich.storage;
    redis.port = services.immich.redisPort;
  };

  services.postgresql = {
    package = pkgs.postgresql_17; # current version of db for immich
    dataDir = services.postgresql.storage;
    # default port
  };

  services.jellyfin = {
    enable = true;
    # apparently jellyfin has discontinued hardware acceleration for rpi
    dataDir = services.jellyfin.storage;
  };

  services.paperless = {
    enable = true;
    settings = {
      PAPERLESS_URL = "https://${services.paperless.prefix}.${domain}";
      PAPERLESS_OCR_LANGUAGE = "ces+eng";
      PAPERLESS_OCR_USER_ARGS = {
        optimize = 1;
        pdfa_image_compression = "lossless";
      };
    };
    port = services.paperless.port;
    dataDir = "${services.paperless.storage}/data";
    mediaDir = "${services.paperless.storage}/media";
    consumptionDir = "${services.paperless.storage}/consumption";
    environmentFile = config.age.secrets.paperless-env.path;
  };

  # DHCP on the home network is providing DNS server pointing to the IP address of this device.
  # Not part of the nixos configuration.
  services.adguardhome = {
    # NOTE: adguardhome is using private systemd folder,
    # as long as it's all configured in nix i dont care enough to migrate
    # the StateDirectory / RuntimeDirectory to `backed-services`.
    enable = true;
    host = "127.0.0.1";
    port = services.adguard.port;
    settings = {
      dns = {
        upstream_dns = [
          "1.1.1.1"
          "8.8.8.8"
          "9.9.9.9"
        ];
      };
      filtering = {
        protection_enabled = true;
        filtering_enabled = true;
      };
      # The following notation uses map
      # to not have to manually create {enabled = true; url = "";} for every filter
      # This is, however, fully optional
      filters =
        map
          (url: {
            enabled = true;
            url = url;
          })
          [
            "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_2_Base/filter.txt" # base list
            "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_3_Spyware/filter.txt" # spyware
            "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_4_Social/filter.txt" # like and tweet buttons on websites
            "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt" # The Big List of Hacked Malware Web Sites
            "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt" # malicious url blocklist
          ];
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      53
      80
      443
    ];
    allowedUDPPorts = [
      53
    ];
  };

}
