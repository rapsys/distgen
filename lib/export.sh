#! /bin/sh -e

# Clear config
cat /dev/null > root.conf

# Append every config parameters
for i in `cat config/*.conf | perl -pne 'undef $_ if /^#/; s/=.*$//'`; do
	echo "$i='$(eval echo \$$i)'" | tee -a root.conf
done

# Virtualbox doc
cat << EOF > root/virtualbox
# VirtualBox disk creation commands
VBoxManage internalcommands createrawvmdk -filename '$VBHDDIR/sda.vmdk' -rawdisk '${PWD}/${SDA}'
VBoxManage internalcommands createrawvmdk -filename '$VBHDDIR/sdb.vmdk' -rawdisk '${PWD}/${SDB}'

Fix ownership of '${PWD}/${SDA}', '${PWD}/${SDB}', '${VBHDDIR}/sda.vmdk' and '${VBHDDIR}/sdb.vmdk' if you to use these as user

# VirtualBox configuration
Go in file/preferences.../network/host-only networks" >> root.virtualbox
Add a new host-only networkd IPv4=${NETGATEWAY4}/IPv4 Mask=255.255.255.0/IPv6=${NETGATEWAY6}/IPv6 Mask=64/DHCP Server=disabled" >> root.virtualbox

# Virtual Machine Configuration
Create a new virtual machine : Type=Linux/Version=Mageia(${ARCH})/Do not add a virtual hard disk
Open the settings of the virtual machine

Section Storage
In controller SATA click on add hard disk, select choose existing disk, sda.vmdk, same with sdb.vmdk

Section Network
Change 'Attached to' to 'Host-only adapter'
Under advanced change MAC Address to ${NETMAC}
EOF

# Dhcpd.conf
cat << EOF > root/dhcpd.conf
# No ddns update
ddns-update-style none;

# Set domain name
option domain-name "${NETHOSTNAME#*.}";

# Set server name
option domain-name-servers ${NETDNS/ /, };

# Set least timings
default-lease-time 600;
max-lease-time 1050;

# ${NETADDRESS4%.*}.0/${NETADDRESS4#*/} subnet
subnet ${NETADDRESS4%.*}.0 netmask 255.255.255.0 {
	# default gateway
	option routers ${NETGATEWAY4};
}

host virtualbox {
	hardware ethernet ${NETMAC};
	fixed-address ${NETADDRESS4%/*};
}
EOF

# Dhcpd6.conf
cat << EOF > root/dhcpd6.conf
# No ddns update
ddns-update-style none;

# Set least timings
default-lease-time 600;
max-lease-time 7200;

# Enable RFC 5007 support (same than for DHCPv4)
allow leasequery;

# vboxnet0 shared network
shared-network vboxnet0 {
	# Set domain name
	option domain-name "${NETHOSTNAME#*.}";

	# Set server name
#	option dhcp6.name-servers ${NETGATEWAY6};

	# private ${NETADDRESS6%::*}::/${NETADDRESS6#*/} subnet
	subnet6 ${NETADDRESS6%::*}::/${NETADDRESS6#*/} {
		# Default range
		range6 ${NETADDRESS6%::*}::2 ${NETADDRESS6%::*}::ffff:ffff;
	}

	# shared fe80::/64 subnet
	subnet6 fe80::/64 {
	}
}

host virtualbox {
	# Client DUID
	#XXX: only work for ipv4 : hardware ethernet ${NETMAC};
	#XXX: see journalctl -u dhcpd6.service to get virtualbox machine DUID
	host-identifier option dhcp6.client-id 00:00:00:00:00:00:00:00:00:00:00:00:00:00;
	# Set address
	fixed-address6 ${NETADDRESS6%/*};
}
EOF

# Radvd.conf
cat << EOF > root/radvd.conf
# Radvd configuration
interface vboxnet0
{
	# Announce at regular interval
        AdvSendAdvert on;
	# Start service even if vboxnet0 is missing
	IgnoreIfMissing on;
	# Force the configuration of client through dhcpv6
	AdvManagedFlag on;
	AdvOtherConfigFlag on;

	prefix ${NETADDRESS6%::*}::/${NETADDRESS6#*/} {
		# Announce that all address prefix are on-link
		AdvOnLink on;
		# Announce that the prefix can be used for autonomous address configuration
		#XXX: off require a dhcpd6 configuration
		AdvAutonomous off;
		# Announce that the interface address is sent instead of network prefix
		AdvRouterAddr off;
	};

	prefix ${NETGATEWAY6}/128 {
		AdvOnLink on;
		AdvAutonomous off;
		AdvRouterAddr on;
	};
};
EOF
