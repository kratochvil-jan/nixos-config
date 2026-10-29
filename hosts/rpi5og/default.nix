{ inputs, ... }:

# Rpi5 with vanilla kernel

inputs.nixpkgs.lib.nixosSystem {
  system = "aarch64-linux";
  specialArgs = { inherit inputs; };
  modules = [
    (
      {
        config,
        modulesPath,
        lib,
        ...
      }:
      {
        nixpkgs.hostPlatform = "aarch64-linux";
        nixpkgs.buildPlatform = config.nixpkgs.hostPlatform;
        imports = [
          "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
          "${modulesPath}/profiles/minimal.nix"
          ../common.nix
          ../ssh.nix
        ];
        sdImage.compressImage = false;
        boot.zfs.forceImportRoot = false;
        boot.supportedFilesystems.zfs = lib.mkForce false;

        system.stateVersion = "26.05";
        hardware.enableRedistributableFirmware = lib.mkForce false;

        # override defaults from sd-image-aarch64
        boot.kernelParams = lib.mkForce [
          "console=ttyAMA10,115200n8"
          "console=tty0"
          "earlycon=pl011,0x107d001000,115200n8"
        ];

        hardware.bluetooth.enable = false;

        boot.loader.grub.enable = false;
        boot.loader.generic-extlinux-compatible.enable = true;

        networking = {
          hostName = "rpi5og";
          firewall.enable = true;
          nftables.enable = true;
        };
        fileSystems."/".options = [ "noatime" ];
        services.getty.autologinUser = lib.mkForce "root";
        services.openssh.settings.PermitRootLogin = "yes";
        users.users.root = {
          openssh.authorizedKeys.keyFiles = [
            ./secrets/hosts/lap/jan.pub
          ];
          password = null;
        };
      }
    )
  ];
}
