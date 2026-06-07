{ config, ... }:

{
  services.immich = {
    enable = true;
    port = config.home-cloud.immich.port;
    host = "0.0.0.0"; # to access from devices via network
    openFirewall = true;
    accelerationDevices = [ "/dev/dri/renderD128" ];
    machine-learning.enable = true;
    settings.newVersionCheck.enabled = false;
    mediaLocation = config.home-cloud.immich.path;
  };

  systemd.tmpfiles.rules = [
    "d ${config.home-cloud.immich.path} 0750 ${config.services.immich.user} ${config.services.immich.group} -"
  ];
}
