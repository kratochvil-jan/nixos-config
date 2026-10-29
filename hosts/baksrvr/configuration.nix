{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # Disk
    inputs.disko.nixosModules.disko
    ./disk-config.nix

    # Age
    inputs.agenix.nixosModules.default

    # System
    ../common.nix
    ../ssh.nix

    # Users
    ../users/root.nix
    ../users/jan.nix
    ../../home/jan/hosts/baksrvr.nix

    # Home Manager
    ../home-manager.nix
  ];

  hardware.facter.reportPath = ./facter.json;

  age.secrets.jan-pw.file = ../../secrets/hosts/baksrvr/jan.pw.age;
  # age.secrets.lap-wg.file = ../../secrets/hosts/lap/wg.key.env.age;

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
    hashedPasswordFile = config.age.secrets.jan-pw.path;
    openssh.authorizedKeys.keyFiles = [
      ../../secrets/hosts/lap/jan.pub
      ../../secrets/hosts/phone/key.pub
    ];
  };

  boot.zfs.forceImportRoot = false;

  # Firmware

  hardware.enableRedistributableFirmware = true;
  services.fwupd.enable = true;

  # Bootloader

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "2";
  boot.loader.efi.canTouchEfiVariables = true;

  # Headless setup
  hardware.graphics.enable = false;
  security.rtkit.enable = false;
  services.pipewire.enable = false;
  services.libinput.enable = false;

  systemd.oomd.enable = true;

  services.thermald.enable = true;

  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "power";

      # Allow PCI devices to suspend when idle
      RUNTIME_PM_ON_AC = "auto";

      SATA_LINKPWR_ON_AC = "med_power_with_dipm";

      USB_AUTOSUSPEND = 1;

      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 50;
    };
  };

  networking.wireless.enable = false;
  boot.blacklistedKernelModules = [
    "iwlwifi"
  ];

  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocker = "ignore";
  };

  hardware.bluetooth.enable = false;
  hardware.nvidiaOptimus.disable = true;

  services.fstrim.enable = true;
  # `btrfs scrub status /`
  # `btrfs scrub start /`
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  networking = {
    hostName = "baksrvr";
    usePredictableInterfaceNames = lib.mkDefault true;
    networkmanager.enable = false;
    firewall.enable = true;
    nftables.enable = true;
  };
  services.resolved.enable = true;
  services.avahi.enable = true;

  system.stateVersion = "26.11";
}
