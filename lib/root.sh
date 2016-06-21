#! /bin/sh -e

# Make mount point
mkdir -p ${MOUNTPOINT}

# Mount slash filesystem
mount /dev/mapper/${SLASHNAME} ${MOUNTPOINT}

# Make boot in mount point
mkdir -p ${MOUNTPOINT}/boot

# Mount boot filesystem
mount /dev/md/${MDBOOT} ${MOUNTPOINT}/boot

