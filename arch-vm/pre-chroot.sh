# 1. Setup Partitions (Manual part - assume /dev/vda)
mkfs.fat -F 32 /dev/vda1
mkfs.btrfs -f /dev/vda2

# 2. Subvolume Logic
mount /dev/vda2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@log
mkdir /mnt/.snapshots  # THE "SAFE" SNAPSHOT FOLDER
umount /mnt

# 3. Mount Everything
mount -o compress=zstd,subvol=@ /dev/vda2 /mnt
mkdir -p /mnt/{boot,home,nix,var/log}
mount /dev/vda1 /mnt/boot
mount -o compress=zstd,subvol=@home /dev/vda2 /mnt/home
mount -o compress=zstd,subvol=@nix /dev/vda2 /mnt/nix
mount -o compress=zstd,subvol=@log /dev/vda2 /mnt/var/log

# 4. Base Install
pacstrap -K /mnt base linux linux-firmware btrfs-progs git vim networkmanager sudo

# 5. Generate FSTAB
genfstab -U /mnt >> /mnt/etc/fstab

echo "Done! Now arch-chroot /mnt and run the next script."
