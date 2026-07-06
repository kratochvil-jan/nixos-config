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
        device = "/dev/disk/by-id/ata-Samsung_SSD_850_EVO_1TB_S3PLNF0JA12377F";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            system = {
              label = "ROOTFS";
              type = "8305"; # Linux ARM64 root (/)
              size = "100%";
              content = {
                type = "btrfs";
                subvolumes = {
                  "/rootfs" = {
                    mountpoint = "/";
                    mountOptions = [ "noatime" ];
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "noatime" ];
                  };
                  "/home" = {
                    mountpoint = "/home";
                    mountOptions = [ "noatime" ];
                  };
                  "/log" = {
                    mountpoint = "/var/log";
                    mountOptions = [ "noatime" ];
                  };
                  "/swap" = {
                    mountpoint = "/.swapvol";
                    swap."swapfile" = {
                      size = "8G";
                      priority = 3; # (higher number -> higher priority)
                      # to be used after zswap (set zramSwap.priority > this priority),
                      # but before "hibernation" swap
                      # https://github.com/nix-community/disko/issues/651
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
