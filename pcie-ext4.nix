{ config, lib, ... }:

let
  firmwarePartition = lib.recursiveUpdate {
    # label = "FIRMWARE";
    priority = 1;

    type = "0700"; # Microsoft basic data
    attributes = [
      0 # Required Partition
    ];

    size = "1024M";
    content = {
      type = "filesystem";
      format = "vfat";
      # mountpoint = "/boot/firmware";
      mountOptions = [
        "noatime"
        "noauto"
        "x-systemd.automount"
        "x-systemd.idle-timeout=1min"
      ];
    };
  };

  espPartition = lib.recursiveUpdate {
    # label = "ESP";

    type = "EF00"; # EFI System Partition (ESP)
    attributes = [
      2 # Legacy BIOS Bootable, for U-Boot to find extlinux config
    ];

    size = "1024M";
    content = {
      type = "filesystem";
      format = "vfat";
      # mountpoint = "/boot";
      mountOptions = [
        "noatime"
        "noauto"
        "x-systemd.automount"
        "x-systemd.idle-timeout=1min"
        "umask=0077"
      ];
    };
  };

in
{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/disk/by-id/ata-TOSHIBA_MQ01ABF050_X3QEW0PZT";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            FIRMWARE = firmwarePartition {
              label = "FIRMWARE";
              content.mountpoint = "/boot/firmware";
            };

            ESP = espPartition {
              label = "ESP";
              content.mountpoint = "/boot";
            };
            system = {
              type = "8305"; # Linux ARM64 root (/)
              size = "100%";
              content = {
                type = "filesystem";
                extraArgs = [
                  # "--label nixos"
                  # "-f" # Override existing partition
                ];
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
