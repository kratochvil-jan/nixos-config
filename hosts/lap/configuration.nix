{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    # Hardware
    inputs.nixos-hardware.nixosModules.lenovo-ideapad-slim-5
    ./hardware-configuration.nix

    # Disk
    inputs.disko.nixosModules.disko
    ./disk-config.nix

    # Age
    inputs.agenix.nixosModules.default

    # System
    ../common.nix
    ../arm-cross-compile.nix
    ../desktop.nix

    (import ../dhcp-on-usb-eth-dongle.nix {
      usbEthIfName = "enp4s0f4u2";
      wlanIfName = "wlo1";
    })

    # Users
    ../users/root.nix
    ../users/jan.nix
    ../../home/jan/hosts/lap.nix

    # Home Manager
    ../home-manager.nix
  ];

  hardware.amdgpu.initrd.enable = true;
  hardware.amdgpu.opencl.enable = true;
  hardware.amdgpu.zluda.enable = true;

  boot.kernelParams = [
    "amdgpu"
    # "nomodeset"
    # "systemd.unit=multi-user.target"
    # "systemd.debug-shell=1"
    # "loglevel=7"
  ];

  nix.settings.trusted-users = [
    "root"
    "jan"
    "wheel"
  ];

  # Firmware

  hardware.enableRedistributableFirmware = true;
  services.fwupd.enable = true;

  # Bootloader

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  powerManagement.enable = true;
  powerManagement.powertop.enable = true;

  services.fstrim.enable = true;

  zramSwap.enable = true;

  # `btrfs scrub status /`
  # `btrfs scrub start /`
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  # Security

  # Automatically unlock the user's default KDE wallet upon login
  # Note: the login password should match the wallet password
  security.pam.services."jan".kwallet.enable = true;

  security.pki.certificateFiles = [
    ../../secrets/certs/home-ca.crt
  ];

  # Networking

  networking = {
    hostName = "lap";
    usePredictableInterfaceNames = true;
    networkmanager.enable = true;
    firewall.enable = true;
    nftables.enable = true;
  };
  services.resolved.enable = true;

  networking.wireguard = {
    enable = true;
    # TODO
  };

  # Perihperals
  hardware.spacenavd.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
    settings.General.Experimental = true;
  };

  # Containers

  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "btrfs";
  virtualisation.docker.daemon.settings.experimental = true;

  # Virtualisation

  virtualisation.libvirtd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
  # TODO win10 VM for device updates
  programs.virt-manager.enable = true;

  # Graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Audio

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    extraConfig.pipewire = {
      "98-crackling-fix" = {
        "context.properties" = {
          "default.clock.quantum" = 1024;
          "default.clock.min-quantum" = 1024;
          "default.clock.max-quantum" = 8192;
        };
      };
    };
  };

  # Services

  systemd.oomd.enable = true;

  # TODO move me
  services.sunshine = {
    enable = true;
    autoStart = false;
    openFirewall = true;
  };

  services.touchegg.enable = true;
  services.libinput.enable = true;

  # services.printing = {
  #   # CUPS
  #   enable = true;
  #   drivers = [ pkgs.hplipWithPlugin ];
  # };

  # Programs

  programs.wireshark.enable = true;
  programs.winbox = {
    enable = true;
    openFirewall = true;
  };

  programs.steam.enable = true;

  programs.localsend.enable = true;

  programs.ssh.startAgent = true;

  programs.dconf.enable = true;

  system.stateVersion = "25.11";
}
