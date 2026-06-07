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
      boot-sd = {
        device = "/dev/disk/by-id/mmc-SC16G_0x3c4fd0d8";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            FIRMWARE = firmwarePartition {
              label = "SD_FIRMWARE";
              content.mountpoint = "/boot/firmware";
            };

            ESP = espPartition {
              label = "SD_ESP";
              content.mountpoint = "/boot";
            };
          };
        };
      };
      main = {
        device = "/dev/disk/by-id/ata-TOSHIBA_MQ01ABF050_X3QEW0PZT";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            system = {
              label = "PCIE_NIXOS";
              type = "8305"; # Linux ARM64 root (/)
              size = "100%";
              content = {
                type = "filesystem";
                extraArgs = [
                  # "--label nixos"
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
