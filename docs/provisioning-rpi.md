# Rpi5

Using the flake [nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi) due to the PCIe hat. Untested on OG aarch64 system (yet)

## Filesystem
- `mmcblk0p1` - vfat with firmware + initrd
- `XXX` - rootfs on SSD via PCIe

## Provisioning

Two-step process:
1. Flash and boot a USB stick with a live system
2. Plug in the peripherals for the system - SD card (bootloared, firmware, initrd) + disk storage on PCIe
   - (Optional) external storage does not need to be plugged in right now, depends on the system's disk config

`$ nix build .\#sdImages.rpi5`

Replace DEV with USB blkid
`# dd if=./result/sd-image/nixos-image-rpi5-kernel.img of=<DEV> bs=4M conv=fsync status=progress`

Boot the image. Verify if it's booting via UART or SSH as root.

Provision the system via `nixos-aynwhere`:
`$ nix run github:nix-community/nixos-anywhere -- --flake .#rpi5 --target-host root@<IP> -i ./test-rpi --phases disko,install,reboot`

This repartitions and writes data to SD card (firmware) and the rootfs the disk.
After reboot the system should be full, booted with rootfs on the external PCIE disk.
Verify with `lsblk`.

NOTE: the nixos-anywhere command uses ssh for connectivity. The command assumes this is run from `lap`, which has the private key configured in the

## Update
Typical `nixos-rebuild switch`

# Rpi3

My rpi3 image uses OG aarch64 system. I do not need the proprietary system/drivers/bootloader.

## Filesystem
- `mmcblk0p1` - vfat with firmware
- `mmcblk0p2` - ext4 rootfs

**note** The SD card on Rpi3 appears to be limited to 20MBps on Read / 14 MBPs on Write.

**note** Another option was to run on USB flash storage, which was a bit faster (around 30MBps). However this is a backup device and it's easier to have the SD card flush with the Rpi3 box, rather than the USB sticking out.

## Flashing - SD image
`$ nix build .\#sdImages.rpi3`nixosConfigurations.rpi3.config.system.build.sdImage`

`# dd if=./result/sd-image/nixos-image-6.18.26-rpi3-sd-card-26.05.20260505.549bd84-aarch64-linux.img of=/dev/mmcblk0 bs=4M conv=fsync status=progress`

## Update
Typical `nixos-rebuild switch`
