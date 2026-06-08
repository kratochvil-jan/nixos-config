{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

{

  age.secrets.pi.file = ../../../secrets/users/rpi3/pi.age;
  age.secrets.wifi.file = ../../../secrets/wifi.env.age;

  imports = [
    inputs.agenix.nixosModules.default
    ../bootable-sd.nix
    ../cloud.nix
  ];
  users.users.pi = {
    isNormalUser = true;
    hashedPasswordFile = config.age.secrets.pi.path;
    openssh.authorizedKeys.keyFiles = [
      ../../../test-rpi.pub
      ../../../secrets/hosts/lap/users/jan.pub
    ];
  };

  # TODO
  users.users.root.openssh.authorizedKeys.keyFiles = [
    ../../../test-rpi.pub
    ../../../secrets/hosts/lap/users/jan.pub
  ];
  users.users.root.initialPassword = "changeme";

  networking.hostName = "rpi3";
  services.openssh.enable = true;
  services.resolved.enable = true;
  networking.firewall.enable = true;
  networking.nftables.enable = true;
  networking.networkmanager.enable = false;
  networking.wireless.enable = true;
  networking.wireless.userControlled = true;
  boot.extraModprobeConfig = ''
    options brcmfmac power_save=0
  '';
  networking.useNetworkd = true;
  systemd.network = {
    enable = true;
    networks."enu1u1u1" = {
      matchConfig.Name = "enu1u1u1";
      networkConfig.DHCP = "yes";
      dhcpV4Config.RouteMetric = 100;
    };

    networks."20-wifi" = {
      matchConfig.Name = "wlan0";
      networkConfig.DHCP = "yes";
      dhcpV4Config.RouteMetric = 200;
    };
    wait-online.anyInterface = true;
  };

  systemd.services.wpa_supplicant.serviceConfig.EnvironmentFile = config.age.secrets.wifi.path;
  networking.wireless.extraConfig = ''
    country=CZ
    network={
            ssid="$WIFI_SSID"
            bssid=$WIFI_BSSID
            psk="$WIFI_PSK"
            key_mgmt=WPA-PSK WPA-EAP FT-PSK FT-EAP
            mesh_fwding=1
    }
  '';

  environment.systemPackages = with pkgs; [
    vim
    wget
    htop
    ncdu
    ripgrep
    dtc
    inputs.agenix.packages.${system}.default
  ];

  system.stateVersion = "26.05";
}
