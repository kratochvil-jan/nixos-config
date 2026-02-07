{ usbEthIfName, wlanIfName }:

{ pkgs, ... }:

{
  networking.networkmanager.unmanaged = [ usbEthIfName ];
  systemd.network.enable = true;
  systemd.network.wait-online.enable = false;

  networking.nat = {
    enable = true;
    externalInterface = wlanIfName;
    internalInterfaces = [ usbEthIfName ];
  };

  systemd.network.networks."10-usb-eth" = {
    matchConfig.Name = usbEthIfName;
    networkConfig = {
      Address = "10.233.0.1/24";
      DHCPServer = true;
    };
    dhcpServerConfig = {
      PoolOffset = 10;
      PoolSize = 10;
      EmitDNS = true;
      DNS = "1.1.1.1";
      EmitRouter = true;
    };
    linkConfig.RequiredForOnline = "no";
  };

  networking.firewall.interfaces.${usbEthIfName}.allowedUDPPorts = [ 67 ];
}
