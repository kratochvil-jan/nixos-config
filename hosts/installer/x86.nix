{
  inputs,
}:

inputs.nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = { };
  modules = [
    (
      { lib, modulesPath, ... }:
      {
        imports = [
          (modulesPath + "/installer/cd-dvd/installation-cd-minimal-new-kernel-no-zfs.nix")
        ];
        boot.supportedFilesystems = [
          "btrfs"
          "vfat"
          "ext4"
        ];
        virtualisation.vmVariant = {
          # ssh -p 2222 root@127.0.0.1
          virtualisation.qemu.networkingOptions = lib.mkForce [
            "-net"
            "nic,netdev=user.0,model=virtio"
            "-netdev"
            "user,id=user.0,$QEMU_NET_OPTS,hostfwd=tcp::2222-:22"
          ];
          virtualisation.qemu.options = [
            "-nographic"
          ];
        };
        isoImage.configurationName = lib.mkDefault "Simple x86 live system for nixos-anywhere";
        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
        time.timeZone = "Europe/Prague";
        networking.hostName = "nixos-installer";
        services.avahi.enable = true;
        services.getty.autologinUser = lib.mkForce "root";
        users.users.root.initialHashedPassword = lib.mkForce null;
        users.users.root.initialPassword = "1";
        services.openssh.enable = true;
        services.openssh.settings.PermitRootLogin = "yes";
        services.openssh.settings.PasswordAuthentication = true;
      }
    )
  ];
}
