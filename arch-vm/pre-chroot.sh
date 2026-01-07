# Setup Partitions
mkfs.fat -F 32 -n BOOT /dev/vda1
mkfs.btrfs -L ARCH /dev/vda2

# Define the mount options for SSD performance
# - compress=zstd: Saves space and SSD wear
# - noatime: Stops the OS from writing to the disk every time you just 'read' a file
OPTS="compress=zstd,noatime"

# Create Subvolumes
mount /dev/vda2 /mnt
btrfs subvolume create /mnt/@             # Ephemeral Root
btrfs subvolume create /mnt/@home         # Persistent User Data
btrfs subvolume create /mnt/@nix          # Persistent Nix Store
btrfs subvolume create /mnt/@persist      # Persistent System Configs
btrfs subvolume create /mnt/@log          # Persistent Logs
btrfs subvolume create /mnt/@pkg          # Persistent Pacman Cache
btrfs subvolume create /mnt/@db           # Persistent Pacman Database
# Take a snapshot of empty root. On every boot, we will delete the dirty @ and replace it with this @blank
btrfs subvolume snapshot -r /mnt/@ /mnt/@blank

umount /mnt

# Mount everything in place
mount -o $OPTS,subvol=@ /dev/vda2 /mnt
mkdir -p /mnt/{boot,home,nix,persist,var/log,var/cache/pacman/pkg,var/lib/pacman}

mount /dev/vda1 /mnt/boot
mount -o $OPTS,subvol=@home /dev/vda2 /mnt/home
mount -o $OPTS,subvol=@nix /dev/vda2 /mnt/nix
mount -o $OPTS,subvol=@persist /dev/vda2 /mnt/persist
mount -o $OPTS,subvol=@log /dev/vda2 /mnt/var/log
mount -o $OPTS,subvol=@pkg /dev/vda2 /mnt/var/cache/pacman/pkg
mount -o $OPTS,subvol=@db /dev/vda2 /mnt/var/lib/pacman

# Base Install
pacstrap -K /mnt base base-devel linux linux-firmware btrfs-progs git vim networkmanager sudo

# Generate FSTAB
genfstab -U /mnt >> /mnt/etc/fstab

# Add the ".snapshots" management mount
UUID=$(blkid -s UUID -o value /dev/vda2)
mkdir -p /mnt/.snapshots
# we use subvolid=5 to tell Linux we want the absolute root of the disk
echo "UUID=$UUID /.snapshots btrfs subvolid=5,$OPTS 0 0" >> /mnt/etc/fstab

echo "Phase 1 Complete. Now enter: arch-chroot /mnt"
