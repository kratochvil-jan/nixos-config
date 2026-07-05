{
  virtualisation.oci-containers.containers.home-assistant = {
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
}
