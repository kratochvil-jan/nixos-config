{ lib, raid-devices, ... }:

assert builtins.isList raid-devices;

{
  # first raid device
  device = lib.head raid-devices;
  type = "disk";
  content = {
    type = "btrfs";
    extraArgs = [
      "--force" # Override existing partition
      "--label"
      "raid"
      "--data"
      "raid1"
      "--metadata"
      "raid1"
    ]
    # the rest of the devices
    ++ lib.tail raid-devices;
    subvolumes = {
      "@data" = {
        mountpoint = "/storage/raid/data";
      };
      "@media" = {
        mountpoint = "/storage/raid/media";
      };
      "@snapshots-services" = {
        mountpoint = "/storage/raid/snapshots-services";
      };
      "@snapshots-lap" = {
        mountpoint = "/storage/raid/snapshots-lap";
      };
    };
  };
}
