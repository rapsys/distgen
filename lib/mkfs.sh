#! /bin/sh -e

# Create /boot on it
#XXX: it seems it's not possible to boot from ext4 or xfs V5 with grub-legacy anymore
mkfs.ext3 -L 'boot' -U ${BOOTUUID} /dev/md/${MDBOOT}

# Create swap on it
mkswap -L 'swapa' -U ${SWAPAUUID} ${LOOPA}p3
mkswap -L 'swapb' -U ${SWAPBUUID} ${LOOPB}p3

# Create filesystem
mkfs.btrfs -L 'data' -U ${DATAUUID} /dev/mapper/${DATANAME}

# Make mount point
mkdir -p ${MOUNTPOINT}

# Mount base filesystem
mount /dev/mapper/${DATANAME} ${MOUNTPOINT}

# Create slash subvolume
btrfs subvolume create ${MOUNTPOINT}/slash

# Create home subvolume
btrfs subvolume create ${MOUNTPOINT}/home

# Set slash as default
btrfs subvolume set-default $(btrfs subvolume list ${MOUNTPOINT} | grep slash | perl -pne 's/^ID\s([0-9]+)\s.*$/\1/') ${MOUNTPOINT}

# Unmount slash filesystem
umount ${MOUNTPOINT}
