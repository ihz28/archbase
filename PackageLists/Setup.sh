#!/bin/bash
su
cd /
umount /.snapshots
rm -r /.snapshots
snapper -c root create-config /
btrfs subvolume delete /.snapshots

mkdir /.snapshots
mount -a

sed -i '22s/""/"wheel"/' /etc/snapper/configs/root
sed -i '44s/"yes"/"no"/' /etc/snapper/configs/root
sed -i '51s/"10"/"5"/' /etc/snapper/configs/root
sed -i '52s/"10"/"5"/' /etc/snapper/configs/root
sed -i '54s/"10"/"0"' /etc/snapper/configs/root
sed -i '55s/"10"/"0"/' /etc/snapper/configs/root
sed -i '53s/"10"/"0"/' /etc/snapper/configs/root

chown -R :wheel /.snapshots
snapper -c root create -d "***Base System***"
grub-mkconfig -o /boot/grub/grub.cfg

reboot
