#! /bin/sh -e

# Bind mount /dev
mount --bind /dev ${MOUNTPOINT}/dev

# Bind mount /proc
mount --bind /proc ${MOUNTPOINT}/proc

# Bind mount /sys
mount --bind /sys ${MOUNTPOINT}/sys

# Backup old mtab
mv ${MOUNTPOINT}/etc/mtab ${MOUNTPOINT}/etc/mtab.orig

# Create new mtab
#cat /proc/self/mounts | grep -E '^(/dev/m|devtmpfs)' | perl -pne 's%/media(/?)%$1%' | sort | uniq > /media/etc/mtab
perl -pne "/^(devtmpfs \\/dev|\\/dev\\/(md|dm|mapper))/ || undef \$_; s%${MOUNTPOINT}/?%/%" /proc/self/mounts > ${MOUNTPOINT}/etc/mtab

# Extract last kernel version
KVER=`chroot ${MOUNTPOINT} rpm -qa | perl -pne '/kernel-server-latest/||undef $_;s%^kernel-(server)-latest-([^-]+)-(.+)$%\2-\1-\3%'`

# Regenerate initrd
#XXX: force non hostonly else it don't store commandline : rd.luks.uuid rd.md.uuid ip=dhcp rd.neednet=1
DRACUT_SKIP_FORCED_NON_HOSTONLY=1 chroot ${MOUNTPOINT} mkinitrd -f /boot/initrd-${KVER}.img ${KVER}

# Generate grub config
chroot ${MOUNTPOINT} grub2-mkconfig -o /boot/grub2/grub.cfg

# Install grub
for i in $LOOPB $LOOPA; do
	chroot ${MOUNTPOINT} grub2-install $i
done

# Umount dev
umount ${MOUNTPOINT}/sys

# Umount dev
umount ${MOUNTPOINT}/proc

# Umount dev
umount ${MOUNTPOINT}/dev

# Reset mtab
mv -f ${MOUNTPOINT}/etc/mtab.orig ${MOUNTPOINT}/etc/mtab

# Umount home
umount ${MOUNTPOINT}/home

# Umount boot
umount ${MOUNTPOINT}/boot
