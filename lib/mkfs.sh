#! /bin/sh -e

# Create /boot on it
#XXX: it seems it's not possible to boot from ext4 or xfs V5 with grub-legacy anymore
mkfs.ext3 -L 'boot' -U ${BOOTUUID} /dev/md/${MDBOOT}

# Create swap on it
mkswap -U ${SWAPAUUID} ${LOOPA}p3
mkswap -U ${SWAPBUUID} ${LOOPB}p3

# Create filesystem
mkfs.btrfs -L 'slash' -U ${SLASHUUID} /dev/mapper/${SLASHNAME}

# Create filesystem
mkfs.btrfs -L 'data' -U ${DATAUUID} /dev/mapper/${DATANAME}
