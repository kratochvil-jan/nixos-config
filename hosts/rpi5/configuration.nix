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
    ../ssh.nix

    # Users
    ../users/root.nix
    ../users/jan.nix
    ../../home/jan/hosts/rpi5.nix

    # Home Manager
    ../home-manager.nix

    ./cloud.nix
  ];

  age.secrets.rpi5-jan-pw.file = ../../secrets/hosts/rpi5/jan.pw.age;
  age.secrets.nix-store-key.file = ../../secrets/nix-store-key.age;

  # Users
  users.mutableUsers = false;

  users.users.root = {
    openssh.authorizedKeys.keyFiles = [
      ../../secrets/hosts/lap/jan.pub
    ];
    password = null;
  };

  users.users.jan = {
    initialPassword = lib.mkForce null;
    hashedPasswordFile = config.age.secrets.rpi5-jan-pw.path;
    openssh.authorizedKeys.keyFiles = [
      ../../secrets/hosts/lap/jan.pub
    ];
  };

  systemd.oomd.enable = true;

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

  system.stateVersion = "26.05";
}
