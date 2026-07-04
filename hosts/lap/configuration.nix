{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  systems = (import ../../secrets/systems/default.nix).systems;
in
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

    # ../../modules/home-cloud.nix
    ../rpi3/cloud.nix
  ];

  age.secrets.lap-jan-pw.file = systems.lap.users.jan.pw;
  age.secrets.lap-wg.file = ../../secrets/hosts/lap/wg.key.env.age;

  users.mutableUsers = false;
  users.users."jan".initialPassword = lib.mkForce null;
  users.users."jan".hashedPasswordFile = config.age.secrets.lap-jan-pw.path;

  hardware.amdgpu.initrd.enable = true;
  hardware.amdgpu.opencl.enable = true;
  hardware.amdgpu.zluda.enable = true;

  nix.distributedBuilds = true;
  nix.buildMachines = [
    (import ../rpi3/build-machine.nix)
  ];

  boot = {
    plymouth = {
      enable = true;
      theme = "deus_ex";
      themePackages = with pkgs; [
        # By default we would install all themes
        (adi1090x-plymouth-themes.override {
          selected_themes = [ "deus_ex" ];
        })
      ];
    };

    # Enable "Silent boot"
    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "amdgpu"
      "video=1920x1200"
      "quiet"
      "udev.log_level=3"
      "systemd.show_status=auto"
    ];
    # Hide the OS choice for bootloaders.
    # It's still possible to open the bootloader list by pressing any key
    # It will just not appear on screen unless a key is pressed
    loader.timeout = 0;

  };

  # Firmware

  hardware.enableRedistributableFirmware = true;
  services.fwupd.enable = true;

  # Bootloader

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "2";
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

  # TODO to be removed soon
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
  networking.networkmanager.dns = "systemd-resolved";

  # Wireguard configuration as a NetworkManager profile
  # This way i can toggle on/off the connection
  # via the standard network management applets
  networking.networkmanager.ensureProfiles = {
    # Best way to configure this:
    # 1. Create a wg.conf and test it via `wg-quick up ./wg.conf`
    # 2. Once that works, import the conf into NetworkManager,
    #    via `nmcli connection import type wireguard file ./wg.conf`
    # 3. If that works, convert this imperative config
    #    into declarative for NetworkManager:
    #    `sudo su -c "cd /etc/NetworkManager/system-connections && nix --extra-experimental-features 'nix-command flakes' run github:Janik-Haag/nm2nix | nix --extra-experimental-features 'nix-command flakes' run nixpkgs#nixfmt-rfc-style"`
    environmentFiles = [ config.age.secrets.lap-wg.path ];
    profiles.wg-67cb5bbc-e7e3-4aa4-b719-3a43b510e1f8 = {
      connection = {
        id = "wg";
        interface-name = "wg";
        type = "wireguard";
        uuid = "67cb5bbc-e7e3-4aa4-b719-3a43b510e1f8";
      };
      ipv4 = {
        address1 = "192.168.216.4/32";
        method = "manual";
      };
      ipv6 = {
        addr-gen-mode = "stable-privacy";
        method = "disabled";
      };
      proxy = { };
      wireguard = {
        listen-port = "51820";
        private-key = "$WG_KEY_HOME"; # from env file
      };
      "wireguard-peer.+uVH6IVVxe1gAGo2JbpGYwU7mOE1FXW+dEMTEqL1AiY=" = {
        allowed-ips = "10.0.10.0/24;";
        endpoint = "hjd0a6c2c11.vpn.mynetname.net:23345";
        persistent-keepalive = "30";
      };
    };
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

  # virtualisation.libvirtd.enable = true;
  # virtualisation.spiceUSBRedirection.enable = true;
  # TODO win10 VM for device updates
  # programs.virt-manager.enable = true;

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
          "default.clock.quantum" = 2048;
          "default.clock.min-quantum" = 2048;
          "default.clock.max-quantum" = 8192;
        };
      };
    };
  };

  # SSH

  services.openssh.enable = true;

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

  services.printing = {
    # CUPS
    enable = true;
    drivers = [ pkgs.hplipWithPlugin ];
  };

  # Programs

  programs.wireshark.enable = true;
  programs.winbox = {
    enable = true;
    openFirewall = true;
  };

  programs.steam.enable = true;

  programs.localsend.enable = true;
  programs.kdeconnect.enable = true;

  # TODO
  # programs.ssh.startAgent = true;

  programs.dconf.enable = true;

  system.stateVersion = "25.11";
}
