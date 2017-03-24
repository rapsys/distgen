#! /bin/sh -e

# Umount slash
umount ${MOUNTPOINT}

# Close slash luks partition
cryptsetup close ${DATANAME}

# Stop raids
mdadm --manage /dev/md/${MDBOOT} -S
mdadm --manage /dev/md/${MDDATA} -S

# Detach loops
losetup -d ${LOOPA}
losetup -d ${LOOPB}
