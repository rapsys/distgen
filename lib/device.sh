#! /bin/sh -e

#  Handle both devices
for i in ${SDA} ${SDB}; do
	# Create empty file of 8GB
	dd if=/dev/zero of=${i} bs=$((8192*1024)) count=1024
	# Create partition table
	#XXX: we generate gpt table then fake mbr compat one
	cat << EOF | fdisk ${i}
g
n
1
2048
+256M
t
29
n
2
526336
+4G
t
2
29
n
3
8914944
+2G
t
3
19
n
4
13109248
16777182
t
4
29
x
A
1
M
r
d
n
p
1
2048
+256M
t
fd
n
p
2
526336
+4G
t
2
fd
n
p
3
8914944
+2G
t
3
82
n
p
13109248
16777182
t
4
fd
a
1
p
x
M
r
p
w
EOF
	# Add it with partition scan
	losetup -f -P ${i}
done

# Create raids
mdadm --create /dev/md/${MDBOOT} --level=1 --metadata=0.90 --homehost=${NETHOSTNAME} --name=${MDBOOT} --assume-clean --raid-devices=2 ${LOOPA}p1 ${LOOPB}p1
mdadm --create /dev/md/${MDSLASH} --level=1 --metadata=default --homehost=${NETHOSTNAME} --name=${MDSLASH} --assume-clean --raid-devices=2 ${LOOPA}p2 ${LOOPB}p2
mdadm --create /dev/md/${MDDATA} --level=1 --metadata=default --homehost=${NETHOSTNAME} --name=${MDDATA} --assume-clean --raid-devices=2 ${LOOPA}p4 ${LOOPB}p4

# Create slash luks partition
#XXX: low iter time, should need around 100000 minimum
echo -n $LUKSPASSWORD | cryptsetup -c aes-xts-plain64 -h sha512 -s 512 --iter-time 2000 --use-urandom --uuid ${LUKSSLASHUUID} -d - --batch-mode luksFormat /dev/md/${MDSLASH} 

# Open luks partition
echo -n $LUKSPASSWORD | cryptsetup -d - --batch-mode luksOpen /dev/md/${MDSLASH} ${SLASHNAME}

# Create data luks partition
#XXX: low iter time, should need around 100000 minimum
echo -n $LUKSPASSWORD | cryptsetup -c aes-xts-plain64 -h sha512 -s 512 --iter-time 2000 --use-urandom --uuid ${LUKSDATAUUID} -d - --batch-mode luksFormat /dev/md/${MDDATA} 

# Open luks partition
echo -n $LUKSPASSWORD | cryptsetup -d - --batch-mode luksOpen /dev/md/${MDDATA} ${DATANAME}

