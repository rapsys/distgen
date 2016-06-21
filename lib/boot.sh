#! /bin/sh -e

# Bind mount /dev
mount --bind /dev ${MOUNTPOINT}/dev

# Backup old mtab
mv ${MOUNTPOINT}/etc/mtab ${MOUNTPOINT}/etc/mtab.orig

# Create new mtab
#cat /proc/self/mounts | grep -E '^(/dev/m|devtmpfs)' | perl -pne 's%/media(/?)%$1%' | sort | uniq > /media/etc/mtab
perl -pne "/^(devtmpfs \\/dev|\\/dev\\/(md|dm|mapper))/ || undef \$_; s%${MOUNTPOINT}/?%/%" /proc/self/mounts > ${MOUNTPOINT}/etc/mtab

# Backup old device.map
mv ${MOUNTPOINT}/boot/grub/device.map ${MOUNTPOINT}/boot/grub/device.map.orig

# Install grub
for i in $LOOPB $LOOPA; do
	# Create new device map
	echo "(hd0)	$i" > ${MOUNTPOINT}/boot/grub/device.map

	# Fix grub
	#XXX: e2fs_stage1_5 is 20 sectors embedded, but it fail with gpt
	#XXX: we use install command directly instead of setup (hd0) because it fail with loop
	cat << EOF | chroot ${MOUNTPOINT} grub --device-map=/boot/grub/device.map
root (hd0,0)
install --stage2=/boot/grub/stage2 /grub/stage1 (hd0) /grub/stage2 p /grub/menu.lst
EOF
done

# Restore old device.map
mv -f ${MOUNTPOINT}/boot/grub/device.map.orig ${MOUNTPOINT}/boot/grub/device.map

# Bind mount /proc
mount --bind /proc ${MOUNTPOINT}/proc

# Bind mount /sys
mount --bind /sys ${MOUNTPOINT}/sys

# Extract last kernel version
KVER=`chroot ${MOUNTPOINT} rpm -qa | perl -pne '/kernel-server-latest/||undef $_;s%^kernel-(server)-latest-([^-]+)-(.+)$%\2-\1-\3%'`
# Regenerate initrd
#XXX: force non hostonly else it don't store commandline : rd.luks.uuid rd.md.uuid ip=dhcp rd.neednet=1
DRACUT_SKIP_FORCED_NON_HOSTONLY=1 chroot ${MOUNTPOINT} mkinitrd -f /boot/initrd-${KVER}.img ${KVER}

# Umount dev
umount ${MOUNTPOINT}/sys

# Umount dev
umount ${MOUNTPOINT}/proc

# Umount dev
umount ${MOUNTPOINT}/dev

# Reset mtab
mv -f ${MOUNTPOINT}/etc/mtab.orig ${MOUNTPOINT}/etc/mtab

# Umount boot
umount ${MOUNTPOINT}/boot
