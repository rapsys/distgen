#! /bin/sh -e

# Rsync files (removed P option)
rsync --delete -aAX $DISTCOOK/root/ ${MOUNTPOINT}/

# Fix by hand /var/log/journal
#XXX: see warning about copy on write on btrfs filesystem
#XXX: disable cow on mysql directory as well
chattr +C ${MOUNTPOINT}/var/log/journal ${MOUNTPOINT}/var/lib/mysql
