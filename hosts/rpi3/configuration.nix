{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    # Hardware
    inputs.nixos-raspberrypi.nixosModules.raspberry-pi-3.base

    # Disk
    inputs.disko.nixosModules.disko
    ./disk-config.nix

    # Age
    inputs.agenix.nixosModules.default

    # System
    ../common.nix
    #
    # # Users
    ../users/root.nix
    ../users/jan.nix

    # Home Manager
    ../home-manager.nix
  ];

  # Nix
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate = (_: true);
  nix.settings.trusted-users = [
    "root"
    "jan"
    "wheel"
  ];

  # Bootloader

  boot.loader.raspberry-pi.bootloader = "kernel";
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking

  networking = {
    hostName = "rpi3";

    networkmanager.enable = true;
    wireless.enable = false;
    firewall.enable = true;
    nftables.enable = true;
  };

  # Perihperals
  # empty

  # Virtualisation

  virtualisation.docker.enable = true;

  # Audio

  services.pipewire.enable = false;
  services.pulseaudio.enable = false;

  # Graphics

  hardware.graphics.enable = false;

  # Services

  services.udev.extraRules = ''
    # Ignore partitions with "Required Partition" GPT partition attribute
    # On our RPis this is firmware (/boot/firmware) partition
    ENV{ID_PART_ENTRY_SCHEME}=="gpt", \
      ENV{ID_PART_ENTRY_FLAGS}=="0x1", \
      ENV{UDISKS_IGNORE}="1"
  '';

  system.stateVersion = "23.11"; # Did you read the comment?
}
