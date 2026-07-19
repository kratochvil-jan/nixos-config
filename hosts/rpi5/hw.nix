{ inputs, pkgs, ... }:

{
  imports = [
    # Hardware
    inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.base
    inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.page-size-16k
  ];
  # Bootloader

  # to allow booting from PCIE
  boot.kernelModules = [
    "libata"
    "libahci"
    "ahci"
  ];
  boot.loader.raspberry-pi.bootloader = "kernel";
  # TODO Ideally i want uboot, but this didnt work in last attempts
  # boot.loader.raspberry-pi.bootloader = "uboot";
  # boot.loader.systemd-boot.enable = false;
  # boot.loader.efi.canTouchEfiVariables = true;
  environment.systemPackages = [
    pkgs.dracut # for lsinitrd
  ];
  boot.tmp.useTmpfs = true;

  # RPI
  hardware.raspberry-pi.config.all = {
    dt-overlays = {
      disable-bt.enable = true;
      disable-bt.params = { };
      # needed for radxa penta sata hat
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
  services.udev.extraRules = ''
    # Ignore partitions with "Required Partition" GPT partition attribute
    # On our RPis this is firmware (/boot/firmware) partition
    ENV{ID_PART_ENTRY_SCHEME}=="gpt", \
      ENV{ID_PART_ENTRY_FLAGS}=="0x1", \
      ENV{UDISKS_IGNORE}="1"
  '';

}
