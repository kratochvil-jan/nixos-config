{ inputs, ... }:
{

  imports = [ inputs.disko.nixosModules.disko ];

  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLB512HAJQ-00000_S3W8NF0KC43281";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              priority = 2;
              size = "100%";
              content = {
                type = "btrfs";
                # DANGER
                # extraArgs = [ "-f" ]; # Override existing partition

                # Subvolumes must set a mountpoint in order to be mounted,
                # unless their parent is mounted
                subvolumes = {
                  # Subvolume name is different from mountpoint
                  "/root" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" ];

                  };
                  # Subvolume name is the same as the mountpoint
                  "/home" = {
                    mountOptions = [ "compress=zstd" ];
                    mountpoint = "/home";
                  };
                  # Sub(sub)volume doesn't need a mountpoint as its parent is mounted
                  # "/home/user" = { };
                  # Parent is not mounted so the mountpoint must be set
                  "/nix" = {
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                    mountpoint = "/nix";
                  };
                  # This subvolume will be created but not mounted
                  # "/test" = { };
                  # Subvolume for the swapfile
                  # "/swap" = {
                  # mountpoint = "/.swapvol";
                  # swap = {
                  # swapfile.size = "20M";
                  # swapfile2.size = "20M";
                  # swapfile2.path = "rel-path";
                  # };
                  # };
                };
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
