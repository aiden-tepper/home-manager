# Setup Partitions (Manual part - assume /dev/vda)
mkfs.fat -F 32 /dev/vda1
mkfs.btrfs -f /dev/vda2

# Define the mount options for SSD performance
# - compress=zstd: Saves space and SSD wear
# - noatime: Stops the OS from writing to the disk every time you just 'read' a file
OPTS="compress=zstd,noatime"

# Create the extra subvolumes
mount /dev/vda2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@cache
btrfs subvolume create /mnt/@tmp
umount /mnt

# Mount them with the specific flags
mount -o $OPTS,subvol=@ /dev/vda2 /mnt
mkdir -p /mnt/{boot,home,nix,var/log,var/cache,var/tmp}
mount /dev/vda1 /mnt/boot
mount -o $OPTS,subvol=@home /dev/vda2 /mnt/home
mount -o $OPTS,subvol=@nix /dev/vda2 /mnt/nix
mount -o $OPTS,subvol=@log /dev/vda2 /mnt/var/log
mount -o $OPTS,subvol=@cache /dev/vda2 /mnt/var/cache
mount -o $OPTS,subvol=@tmp /dev/vda2 /mnt/var/tmp

# Base Install
pacstrap -K /mnt base linux linux-firmware btrfs-progs git vim networkmanager sudo

# Generate FSTAB
genfstab -U /mnt >> /mnt/etc/fstab

echo "Done! Now arch-chroot /mnt and run the next script."
