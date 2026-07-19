{ inputs, ... }:

# Fresh sd image that boots fine using nixos-raspberrypi repo.
# UART with tty working.
# Only works with the "kernel" bootloader.
# Kept only for reference.

inputs.nixos-raspberrypi.lib.nixosInstaller {
  system = "aarch64-linux";
  specialArgs = inputs;
  modules = with inputs.nixos-raspberrypi.nixosModules; [
    raspberry-pi-3.base
    (
      { pkgs, ... }:
      {
        boot.kernelParams = pkgs.lib.mkForce [
          "console=ttyS0,115200"
          "nohibernate"
          "loglevel=7"
          "lsm=landlock,yama,bpf"
        ];
        boot.loader.raspberry-pi.enable = true;
        boot.tmp.useTmpfs = true;
        boot.loader.raspberry-pi.bootloader = "kernel";
        boot.loader.systemd-boot.enable = false;
        boot.loader.efi.canTouchEfiVariables = true;
        users.users.root.openssh.authorizedKeys.keyFiles = [ ../secrets/hosts/lap/users/jan.pub ];
      }
    )
  ];
}
