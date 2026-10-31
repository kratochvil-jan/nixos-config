{ inputs, pkgs, ... }:

let
  lib = pkgs.lib;

  # How many disks we are testing in the BTRFS RAID
  disks = [
    "/dev/disk/by-diskseq/2"
    "/dev/disk/by-diskseq/3"
    "/dev/disk/by-diskseq/4"
    "/dev/disk/by-diskseq/5"
  ];

  # creates attrs:
  # {
  #   disk_1 = {
  #     device = "...";
  #     type = "disk";
  #     content.type = "btrfs";
  #   };
  #   disk_2 = ...
  # };
  dummy-disk-defines = builtins.listToAttrs (
    lib.imap1 (i: disk: {
      name = "disk_${toString i}";
      value = {
        device = disk;
        type = "disk";
        content.type = "btrfs";
      };
    }) disks
  );

  minimal-rootfs = {
    type = "disk";
    device = "/dev/disk/by-diskseq/1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          name = "ESP";
          start = "1M";
          end = "128M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "/rootfs" = {
                mountpoint = "/";
              };
              "/home" = {
                mountOptions = [ "compress=zstd" ];
                mountpoint = "/home";
              };
              "/nix" = {
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
                mountpoint = "/nix";
              };
            };
          };
        };
      };
    };
  };
in
inputs.disko.lib.testLib.makeDiskoTest {
  inherit pkgs;
  name = "btrfs-raid";

  disko-config = {
    disko.devices.disk = {
      inherit minimal-rootfs;
      raid = import ../raid1.nix {
        inherit lib;
        raid-devices = disks;
      };
    }
    # Why this exists:
    # - the disko test driver counts number of disks in disko.devices.disk attr
    # - then it provisions that many virtual disks into the VM
    # - this is used just to populate that disko.devices.disk attr, nothing else.
    // dummy-disk-defines;
  };

  extraTestScript = ''
    def check(cmd):
      print(machine.succeed(cmd))

    # first some debug prints
    check("findmnt -t btrfs")
    check("btrfs subvolume list /storage/raid/data")
    check("lsblk")

    # check if the @data subvolume exists and is mounted
    check("btrfs subvolume list /storage/raid/data | grep -q '@data'")
    check("findmnt -t btrfs | grep -q /storage/raid/data")

    check("btrfs filesystem show /dev/disk/by-label/raid")
    check("btrfs filesystem usage /storage/raid/data")

    # make sure the raid has expected count of disks
    output = machine.succeed(
        "btrfs filesystem show /dev/disk/by-label/raid"
    )
    assert output.count("devid") == ${builtins.toString (builtins.length disks)}, output

    # expected RAID type
    check("btrfs filesystem df /storage/raid/data")
    check(
        "btrfs filesystem df /storage/raid/data | "
        "grep -q 'Data, RAID1'"
    )

    check(
        "btrfs filesystem df /storage/raid/data | "
        "grep -q 'Metadata, RAID1'"
    )
  '';
}
