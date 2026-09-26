# Storage

- SSD
    - @rootfs (implicit)
    - [x] services -> /var/lib/backed-services
    - [ ] backed to /storage/backed-services
- HDD 1
    - slow storage
    - non-backed storage
    - [ ] subvol: @scratch
    - unimportant data, never backed up. for data manipulation
- HDDs in RAID1
    - master subvol
    - [x] subvol: @snapshots-services
        - [ ] destination of @backed-services
        - [ ] off-site backups
    - [x] subvol: @snapshots-lap
        - [ ] destination of btrfs snapshot of lap @home to prevent loss of data
        - [ ] off-site backups
    - [ ] subvol: @media (for jellyfin media)
        - [ ] off-site backups
    - [x] subvol: @data (generic data)
        - [ ] off-site backups

- [ ] setup `btrbk`:
    - from SSD to RAID:
        - [ ] @snapshots-services
    - receive to RAID:
        - [ ] @snapshots-lap
    - from RAID to off-site:
        - [ ] off-site storage medium
        - [ ] @snapshots-services
        - [ ] @snapshots-lap
        - [ ] @data
        - [ ] @media
- jelyyfin: library configuration to @media
    - maybe us nixflix - need to test in VM - https://github.com/kiriwalawren/nixflix
-


## Subvolume management
```bash
mkdir -p /mnt/raid-root
mount -t btrfs -o subvolid=5 /dev/disk/by-label/raid /mnt/raid-root
btrfs subvolume create /mnt/raid-root/@media
btrfs subvolume list /mnt/raid-root
btrfs subvolume delete /mnt/raid-root/@medai

mount -t btrfs -o subvol=@media /dev/disk/by-label/raid /storage/raid/media

btrfs subvolume show /storage/raid/data
```

## Restoring
https://github.com/digint/btrbk#restoring-backups

IMPORANT: restoration of a snapshot is via the snapshot command:
```bash
$ ls /snapshots
backed-services.20260926T1605

btrfs subvolume snapshot /snapshots/backed-services.20260926T1605 /var/lib/backed-services/
```
