{ pkgs, ... }:

{
  services.btrbk = {
    instances = {
      "backed-services-to-raid" = {
        onCalendar = "hourly";
        settings = {
          # 7d: For the most recent week, you will have a daily snapshot stored from each day.
          # 4w: After a week, you'll only keep one snapshot per week for the next 4 weeks (so older daily snapshots get removed).
          # 12m: After a month, the policy will keep only monthly snapshots for the next 12 months.
          snapshot_preserve = "7d 4w 12m";
          # The option snapshot_preserve_minensures that all daily snapshots from the last 7 days are preserved, regardless of the other retention rules. It's a safety net to guarantee that no daily snapshot from the past week is deleted prematurely.
          snapshot_preserve_min = "7d";
          target_preserve = "7d 4w 12m";
          volume."/" = {
            subvolume = {
              "/var/lib/backed-services".snapshot_create = "always";
            };
            snapshot_dir = "/snapshots";
            target = "/storage/raid/snapshots-services";
          };
        };
      };
      # "backed-services-to-off-site" = {
      #   onCalendar = "daily";
      #   settings = {
      #     ssh_identity = "TODO";
      #     ssh_user = "btrbk";
      #     stream_compress = "lz4";
      #     volume."/storage/raid" = {
      #       target = "ssh://10.0.10.3/mnt/mybackups";
      #       subvolume = {
      #         "data" = {
      #           snapshot_create = "onchange";
      #         };
      #       };
      #     };
      #   };
      # };
    };
  };
  # Btrbk does not create snapshot directories automatically, so create one here.
  systemd.tmpfiles.rules = [
    "d /snapshots 0755 root root"
  ];
}
