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

# Retrieve mdboot and mddata uuids
MDBOOTUUID=`mdadm --detail /dev/md/${MDBOOT} | perl -pne '/UUID\s:\s/||undef $_;s/^\s+UUID\s:\s//'`
MDDATAUUID=`mdadm --detail /dev/md/${MDDATA} | perl -pne '/UUID\s:\s/||undef $_;s/^\s+UUID\s:\s//'`

# Regenerate initrd
#XXX: request a non hostonly to get all kernel modules
#XXX: provide devices uuid to have md and luks ready
#XXX: force crypttab presence, mandatory to unlocking
#XXX: you may add ip=dhcp rd.neednet=1 for debug purpose
chroot ${MOUNTPOINT} dracut -f -N --fstab --hostonly-cmdline --kernel-cmdline 'rd.luks.uuid='$LUKSDATAUUID' rd.md.uuid='$MDBOOTUUID' rd.md.uuid='$MDDATAUUID -I /etc/crypttab /boot/initrd-${KVER}.img ${KVER}

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

# Umount mysql
umount ${MOUNTPOINT}/var/lib/mysql

# Umount mail
umount ${MOUNTPOINT}/var/spool/mail

# Umount home
umount ${MOUNTPOINT}/home

# Umount boot
umount ${MOUNTPOINT}/boot
