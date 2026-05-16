## Adding swap btrfs subvolume to a running system

### The situation
1. The system has been formatted/partitioned/installed **without** a swapfile enabled
    - The Disko configuration was missing the entry
    - Modifying the Disko config with swap did not actually create the swap subvol and the swapfile.
    - It was only expecting the swapfile to exist, as it only translates to `swapDevices` config
2. Running `# btrfs subvolume create /swap` did not actually create the subvolume in to correct place - it was on the mounted `/` path, not in the `/root` of btrfs
3. It was not desired to re-format the entire system with a fresh disko config due to data loss (althought it's the simplest approach)

### The solution
Adding a `/swap` subvolume on a live system is not so trivial with btrfs.
Note that this system is using LUKS encryption - `/dev/mapper/crypted`

Find the subvolid of the `/root` btrfs volume -> here it's `5`
```bash
# btrfs subvolume list /
ID 256 gen 4096 top level 5 path home
ID 257 gen 4086 top level 5 path nix
ID 258 gen 4096 top level 5 path root
ID 259 gen 21 top level 258 path srv
ID 260 gen 21 top level 258 path var/lib/portables
ID 261 gen 21 top level 258 path var/lib/machines
ID 262 gen 4087 top level 258 path var/tmp
ID 266 gen 4086 top level 5 path swap
```

Mount the `/root` to a new folder
```bash
# mkdir /mnt/btrfs-top
# mount -o subvolid=5 /dev/mapper/crypted /mnt/btrfs-top
```

Create the `/swap` subvole ON the `/root` subvol
```bash
# btrfs subvolume create /mnt/btrfs-top/swap
```

Verify
```bash
# btrfs subvolume list /mnt/btrfs-top
# umount /mnt/btrfs-top
```

Create the swap folder and the swapfile
```bash
# mkdir -p /swap
# mount -t btrfs -o subvol=/swap /dev/mapper/crypted /swap
# btrfs filesystem mkswapfile --size 16g --uuid clear /swap/swapfile
```

Reboot into a system with swap enabled in Disko
```nix
"/swap" = {
  mountpoint = "/swap";
  swap.swapfile.size = "16G";
};
```
