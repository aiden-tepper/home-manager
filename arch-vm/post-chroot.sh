# We need to access the top-level subvolume one last time
mount -t btrfs -o subvolid=5 /dev/vda2 /mnt

# NOW we take the snapshot. 
# Since @ is currently mounted and active as /mnt/@, this captures the installed OS.
btrfs subvolume snapshot -r /mnt/@ /mnt/@blank

# Verify it exists
ls /mnt
# Should see: @  @blank  @nix ...

umount /mnt
reboot
