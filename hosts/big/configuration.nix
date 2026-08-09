{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # TODO FIXME
  ethInterface = "enp0s31f6";
in
{
  imports = [
    # Hardware
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia-nonprime
    ./hardware-configuration.nix

    # Disk
    inputs.disko.nixosModules.disko
    ./disk-config.nix

    # Age
    inputs.agenix.nixosModules.default

    # System
    ../common.nix
    ../ssh.nix
    ../desktop.nix

    # Users
    ../users/root.nix
    ../users/jan.nix
    ../../home/jan/hosts/big.nix

    # Home Manager
    ../home-manager.nix
  ];

  age.secrets.big-jan-pw.file = ../../secrets/hosts/big/jan.pw.age;

  nixpkgs.config.allowUnfree = true;

  users.mutableUsers = false;
  users.users."jan".initialPassword = lib.mkForce null;
  users.users."jan".hashedPasswordFile = config.age.secrets.big-jan-pw.path;

  # Kernel

  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.extraModprobeConfig = ''
    options nvidia NVreg_EnableResizableBar=1
  '';

  # Firmware

  hardware.enableRedistributableFirmware = true;
  services.fwupd.enable = true;

  # Bootloader

  boot.zfs.forceImportRoot = false;
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    # binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  # Networking

  systemd.network.enable = true;
  systemd.network.wait-online.enable = false;
  systemd.network.networks."10-lan" = {
    matchConfig.Name = "lan";
    networkConfig.DHCP = "ipv4";
    linkConfig.RequiredForOnline = "no";
  };

  networking = {
    hostName = "big";
    networkmanager.enable = true;
    interfaces.${ethInterface}.wakeOnLan = {
      enable = true;
      policy = [
        "arp"
        "magic"
      ];
    };

    firewall.enable = true;
    nftables.enable = true;
  };

  services.resolved.enable = true;

  # Perihperals
  # empty

  # SSH

  services.openssh.enable = true;

  # Virtualisation
  # empty

  # Audio

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.pulseaudio.enable = false;
  services.pulseaudio.support32Bit = false;
  hardware.firmware = [ pkgs.sof-firmware ];

  # Desktop

  services.displayManager.sddm.autoLogin.relogin = true;
  services.displayManager.autoLogin.user = "jan";
  services.displayManager.autoLogin.enable = true;

  # Graphics

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;
    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = true;
    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    open = false;
    # Enable the Nvidia settings menu, accessible via `nvidia-settings`.
    nvidiaSettings = true;
  };

  # Programs

  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };
  programs.gamemode.enable = true;
  environment.systemPackages = with pkgs; [ mangohud ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
