#!/bin/bash

mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1
mkfs.btrfs -L ROOT -f /dev/nvme0n1p2
mkswap /dev/nvme0n1p3
mount /dev/nvme0n1p2 /mnt
cd /mnt
btrfs su cr @
btrfs su cr @home
btrfs su cr @snapshots
btrfs su cr @log
btrfs su cr @cache
cd
umount /mnt
mount -o compress=zstd:1,noatime,subvol=@ /dev/nvme0n1p2 /mnt
mount --mkdir -o compress=zstd,noatime,subvol=@home /dev/nvme0n1p2 /mnt/home
mount --mkdir -o compress=zstd,noatime,subvol=@snapshots /dev/nvme0n1p2 /mnt/.snapshots
mount --mkdir -o compress=zstd,noatime,subvol=@log /dev/nvme0n1p2 /mnt/var/log
mount --mkdir -o compress=zstd,noatime,subvol=@cache /dev/nvme0n1p2 /mnt/var/cache
mount --mkdir /dev/nvme0n1p1 /mnt/boot/efi
swapon /dev/nvme0n1p3

reflector --country AU --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
pacstrap -K /mnt base base-devel linux linux-firmware git reflector rsync linux-headers nano
genfstab -U /mnt >> /mnt/etc/fstab
sed -i '/subvolid=/s/subvolid=[^ ,]*,//g' /mnt/etc/fstab
arch-chroot /mnt

