{
  config,
  lib,
  pkgs, # nixpkgs from nixos-raspberrypi
  inputs,
  latestPkgs, # nixpkgs
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko
    # bootloader on SD card
    # rootfs on SSD with btrfs
    ./sd-pcie-btrfs.nix

    # HW specific configs for rpi5
    ./hw.nix

    inputs.agenix.nixosModules.default

    # System
    ../common.nix

    # Users
    ../users/root.nix

    # Home Manager
    ../home-manager.nix

    ./cloud.nix
  ];

  # Nix
  nix.settings.trusted-users = [
    "root"
    "jan"
    "wheel"
  ];

  # Users
  users.mutableUsers = false;

  users.users.root.openssh.authorizedKeys.keyFiles = [
    ../../secrets/hosts/lap/jan.pub
  ];
  users.users.root.password = null;

  # Virtualisation
  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "btrfs";
  virtualisation.docker.daemon.settings.experimental = true;

  # Networking

  networking = {
    hostName = "rpi5";
    dhcpcd.enable = true; # do not use NetworkManager
    dhcpcd.extraConfig = ''
      nohook resolv.conf
    '';
    nameservers = [ "127.0.0.1" ]; # if the adguard DNS fails, it's cooked - no DNS
    wireless.enable = false;
    firewall.enable = true;
    nftables.enable = true;
  };

  # Disable unnecessary
  hardware.bluetooth.enable = false;
  hardware.graphics.enable = false;
  services.pipewire.enable = false;
  services.pulseaudio.enable = false;

  # Services
  services.openssh.enable = true;

  system.stateVersion = "26.05";
}
