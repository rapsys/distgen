#! /bin/sh -e

# Make mount point
mkdir -p ${MOUNTPOINT}

# Mount slash filesystem
mount /dev/mapper/${DATANAME} ${MOUNTPOINT}

# Make boot, home, mail, mysql in mount point
mkdir -p ${MOUNTPOINT}/{boot,home,var/spool/mail,var/lib/mysql}

# Mount boot filesystem
mount /dev/md/${MDBOOT} ${MOUNTPOINT}/boot

# Mount home filesystem
mount -o subvol=/home /dev/mapper/${DATANAME} ${MOUNTPOINT}/home

# Mount mail filesystem
mount -o subvol=/mail /dev/mapper/${DATANAME} ${MOUNTPOINT}/var/spool/mail

# Mount mysql filesystem
mount -o subvol=/mysql /dev/mapper/${DATANAME} ${MOUNTPOINT}/var/lib/mysql
