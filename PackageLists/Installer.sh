#!/bin/bash

# Choose hostname
read -p 'hostname: ' hostname

# localization and time setting
ln -sf /usr/share/zoneinfo/Australia/Perth /etc/localtime
hwclock --systohc
sed -i '171s/#//' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo $hostname > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $hostname.localdomain $hostname" >> /etc/hosts
reflector --country Australia --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syy

# Setup GRUB bootloader and Nvidia drivers
pacman -S --noconfirm amd-ucode
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux
sed -i '6s/"loglevel=3 quiet"/"loglevel=3 quiet nvidia_drm.modeset=1"/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
sed -i '7s/()/(btrfs nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
mkinitcpio -p linux

# INSTALL PACKAGES
pacman -S --noconfirm --needed - < Base.txt
pacman -S --noconfirm --needed - < Wayland_files.txt
pacman -S --noconfirm --needed - < fonts_lists.txt

# ADD ROOT & USER
echo "Root password"
passwd
echo
echo "Adding user"
useradd -m -G wheel ihz
passwd ihz
sed -i '89s/#//' /etc/sudoers

# SETUP ZRAM
echo "[zram0]" > /etc/systemd/zram-generator.conf
echo "zram-size = ram / 2" >> /etc/systemd/zram-generator.conf
systemctl daemon-reload

# INSTALL YAY
cd ~
git clone https://aur.archlinux.org/yay
cd yay
yes | makepkg -si
cd ~
rm -fr yay

# SETUP SNAPPER
yay
yay -S --noconfirm snapper-support
sed -i  '22s/ALLOW_GROUPS=""/ALLOW_GROUPS="wheel"/' /etc/snapper/configs/root
sed -i '44s/TIMELINE_CREATE="yes"/TIMELINE_CREATE="no"/' /etc/snapper/configs/root
sed -i '51s/TIMELINE_LIMIT_HOURLY="10"/TIMELINE_LIMIT_HOURLY="5"/' /etc/snapper/configs/root
sed -i '52s/TIMELINE_LIMIT_DAILY="10"/TIMELINE_LIMIT_DAILY="5"/' /etc/snapper/configs/root
sed -i '54s/TIMELINE_LIMIT_MONTHLY="10"/TIMELINE_LIMIT_MONTHLY="0"' /etc/snapper/configs/root
sed -i '55s/TIMELINE_LIMIT_YEARLY="10"/TIMELINE_LIMIT_YEARLY="0"' /etc/snapper/configs/root
cd /
umount /.snapshots
rm -r /.snapshots
snapper -c root create-config /
btrfs subvolume delete /.snapshots
mkdir /.snapshots
mount -o compress=zstd:1,noatime,subvol=@snapshots /dev/nvme0n1p2 /.snapshots
btrfs subvol set-def 256 /
echo "default subvolume: "
btrfs subvol get-default /
chown -R :wheel /.snapshots
echo
echo "CREATING FIRST SNAPSHOT..."
echo
snapper -c root create -d "***Base Install***"
grub-mkconfig -o /boot/grub/grub.cfg
snapper ls

# SERVICES
systemctl enable NetworkManager
systemctl enable firewalld
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable /dev/zram0

echo
echo "Setup Complete!!"
echo "Check fstab and remove subvol IDs"
