{ inputs, ... }:

# Bootable image from SD / USB.
# Preferably from USB, in order to install a proper system to SD card + SATA storage.

inputs.nixos-raspberrypi.lib.nixosInstaller {
  system = "aarch64-linux";
  specialArgs = inputs;
  modules = with inputs.nixos-raspberrypi.nixosModules; [
    raspberry-pi-5.base
    raspberry-pi-5.page-size-16k
    {
      boot.loader.raspberry-pi.bootloader = "kernel";
      # boot.tmp.useTmpfs = true;
      users.users.root.openssh.authorizedKeys.keyFiles = [ ../secrets/hosts/lap/jan.pub ];

      sdImage.compressImage = false;

      hardware.raspberry-pi.config.all = {
        dt-overlays = {
          pcie-32bit-dma-pi5.enable = true;
          pcie-32bit-dma-pi5.params = { };
        };
        base-dt-params = {
          pciex1 = {
            enable = true;
            value = "on";
          };
          pciex1_gen = {
            enable = true;
            value = "3";
          };
        };
      };
    }
  ];
}
