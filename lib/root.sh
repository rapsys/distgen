#! /bin/sh -e

# Make mount point
mkdir -p ${MOUNTPOINT}

# Mount slash filesystem
mount /dev/mapper/${DATANAME} ${MOUNTPOINT}

# Make boot in mount point
mkdir -p ${MOUNTPOINT}/boot

# Mount boot filesystem
mount /dev/md/${MDBOOT} ${MOUNTPOINT}/boot

# Make home in mount point
mkdir -p ${MOUNTPOINT}/home

# Mount home filesystem
mount -o subvol=/home /dev/mapper/${DATANAME} ${MOUNTPOINT}/home
