{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

{

  age.secrets.wifi = {
    file = ../../secrets/wifi.env.age;
    mode = "700";
    owner = config.systemd.services.wpa_supplicant.serviceConfig.User;
    group = config.systemd.services.wpa_supplicant.serviceConfig.Group;
  };

  imports = [
    inputs.agenix.nixosModules.default
    ./bootable-sd.nix
    ../common.nix
  ];

  users.users.root.openssh.authorizedKeys.keyFiles = [
    ../../secrets/hosts/lap/jan.pub
  ];

  networking.hostName = "rpi3";
  services.openssh.enable = true;
  services.resolved.enable = true;
  networking.firewall.enable = true;
  networking.nftables.enable = true;
  networking.networkmanager.enable = false;
  # disable wireless power saving
  boot.extraModprobeConfig = ''
    options brcmfmac power_save=0
  '';
  networking.wireless = {
    enable = true;
    userControlled = true;
    scanOnLowSignal = false;
  };

  systemd.services.wpa_supplicant.preStart = lib.mkForce ''
    install -d -m 700 /run/wpa_supplicant

    ssid=$(cat ${config.age.secrets.wifi.path} | grep WIFI_SSID |  cut -d= -f2)
    bssid=$(cat ${config.age.secrets.wifi.path} | grep WIFI_BSSID |  cut -d= -f2)
    psk=$(cat ${config.age.secrets.wifi.path} | grep WIFI_PSK |  cut -d= -f2)

    cat > /run/wpa_supplicant/wlan0.conf <<EOF
    ctrl_interface=/run/wpa_supplicant/control
    ctrl_interface_group=wpa_supplicant
    network={
      ssid="$ssid"
      bssid=$bssid
      psk="$psk"
    }
    EOF
  '';

  systemd.services.wpa_supplicant = {
    serviceConfig = {
      ExecStart = lib.mkForce "${pkgs.wpa_supplicant}/bin/wpa_supplicant -i wlan0 -c /run/wpa_supplicant/wlan0.conf";
      UMask = lib.mkForce "066";
      RuntimeDirectory = "wpa_supplicant";
      RuntimeDirectoryMode = "700";
    };
    unitConfig =
      let
        device = "sys-subsystem-net-devices-wlan0.device";
      in
      {
        After = [ device ];
        Wants = [ device ];
        BindsTo = [ device ];
      };
  };

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

  # systemd.services.wpa_supplicant.serviceConfig.EnvironmentFile = config.age.secrets.wifi.path;
  # networking.wireless.extraConfig = ''
  #   country=CZ
  #   network={
  #           ssid="$WIFI_SSID"
  #           bssid=$WIFI_BSSID
  #           psk="$WIFI_PSK"
  #           key_mgmt=WPA-PSK WPA-EAP FT-PSK FT-EAP
  #           mesh_fwding=1
  #   }
  # '';

  environment.systemPackages = with pkgs; [
    vim
    wget
    htop
    gdu
    ripgrep
    dtc
    inputs.agenix.packages.${system}.default
  ];

  system.stateVersion = "26.05";
}
