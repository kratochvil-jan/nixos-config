{ config, ... }:

{
  services.home-assistant = {
    enable = true;
    openFirewall = true;
    configDir = config.home-cloud.home-assistant.path;
    config.http = {
      server_host = "::1";
      server_port = config.home-cloud.home-assistant.port;
      trusted_proxies = [ "::1" ];
      use_x_forwarded_for = true;
    };
    extraComponents = [
      "esphome"
      # Recommended for fast zlib compression
      # https://www.home-assistant.io/integrations/isal
      "isal"
      "met"
    ];

  };

  systemd.tmpfiles.rules = [
    "d ${config.home-cloud.home-assistant.path} 0750 hass hass -"
  ];
}
