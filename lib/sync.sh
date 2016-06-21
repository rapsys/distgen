#! /bin/sh -e

# Rsync files (removed P option)
rsync --delete -aAX $DISTCOOK/root/ ${MOUNTPOINT}/

# Fix by hand /var/log/journal
#XXX: see warning about copy on write on btrfs filesystem
chattr +C ${MOUNTPOINT}/var/log/journal
