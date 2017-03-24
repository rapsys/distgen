#! /bin/sh -e

#  Handle both devices
for i in ${SDA} ${SDB}; do
	# Create empty file of 8GB
	dd if=/dev/zero of=${i} bs=$((8192*1024)) count=1024
	# Create partition table
	#XXX: we generate gpt table
	cat << EOF | gdisk ${i}
o
Y
n
1
2048
+2M
ef02
n
2

+256M
fd00
n
3

+2G
8200
n
4


fd00
w
Y
EOF
	# Add it with partition scan
	losetup -f -P ${i}
done

# Create raids
#XXX: grub2 support standard linux raid1 device
#mdadm --create /dev/md/${MDBOOT} --level=1 --metadata=0.90 --homehost=${NETHOSTNAME} --name=${MDBOOT} --assume-clean --raid-devices=2 ${LOOPA}p2 ${LOOPB}p2
mdadm --create /dev/md/${MDBOOT} --level=1 --metadata=default --homehost=${NETHOSTNAME} --name=${MDBOOT} --assume-clean --raid-devices=2 ${LOOPA}p2 ${LOOPB}p2
mdadm --create /dev/md/${MDDATA} --level=1 --metadata=default --homehost=${NETHOSTNAME} --name=${MDDATA} --assume-clean --raid-devices=2 ${LOOPA}p4 ${LOOPB}p4

# Create slash luks partition
#XXX: low iter time, should need around 100000 minimum
echo -n $LUKSPASSWORD | cryptsetup -c aes-xts-plain64 -h sha512 -s 512 --iter-time 2000 --use-urandom --uuid ${LUKSDATAUUID} -d - --batch-mode luksFormat /dev/md/${MDDATA}

# Open luks partition
echo -n $LUKSPASSWORD | cryptsetup -d - --batch-mode luksOpen /dev/md/${MDDATA} ${DATANAME}
