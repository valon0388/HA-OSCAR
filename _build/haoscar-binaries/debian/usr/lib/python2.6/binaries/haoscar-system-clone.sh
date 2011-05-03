#!/bin/bash

CONFIG_FILE=/usr/share/haoscar/sysimager.conf
[ -f $CONFIG_FILE ] || { echo "Error: $CONFIG_FILE not found!"  && exit -1; }

sed s/:/=/ $CONFIG_FILE > /tmp/sysimager.conf.sh
source /tmp/sysimager.conf.sh

function assert() {
	if [[ ! ${!1} ]]; then
		echo "Error: $1 is not set!!!";
		exit -1; 
	fi
	echo "$1 = ${!1}";
}

function bak() {
	if [ ! -f $1 ]; then
		echo "Backup error: $1 not found";
		return 100;
	fi;
	base_name=$1;
	num=1;
	while [ -f $base_name.bak.$num ]; do
		num=$((num+1)) 
	done
	cp $base_name $base_name.bak.$num;
}

assert "GROUP_NAME";
assert "HA_ETH"; 
assert "IMAGE_DIR";
assert "IMAGE_NAME";
assert "MASK";
assert "PRIMARY_HOSTNAME";
assert "PRIMARY_IP";
assert "SECONDARY_HOSTNAME";
assert "SECONDARY_IP";
assert "SUBNET";

# Then, export these variables to the subshells
export GROUP_NAME;
export HA_ETH; 
export IMAGE_DIR;
export IMAGE_NAME;
export MASK;
export PRIMARY_HOSTNAME;
export PRIMARY_IP;
export SECONDARY_HOSTNAME;
export SECONDARY_IP;
export SUBNET;


rm /tmp/sysimager.conf.sh

if grep "$SECONDARY_HOSTNAME" /etc/hosts; then
	IP=`grep "$SECONDARY_HOSTNAME" /etc/hosts | cut -f 1`;
	if [[ $IP != $SECONDARY_IP ]]; then
		sed s/$IP/$SECONDARY_IP/ /etc/hosts > /tmp/hosts.tmp
		bak /etc/hosts;
		cp /tmp/hosts.tmp > /etc/hosts 
	fi
else
	bak /etc/hosts
	echo "$SECONDARY_IP	$SECONDARY_HOSTNAME" >> /etc/hosts

fi 


if [[ ! -d $IMAGE_DIR ]]; then
	mkdir -p $IMAGE_DIR || 
	{ echo "Cannot create directory: $IMAGE_DIR" && exit -1 ; }
fi

echo "Preparing the golden client ...";
if [ ! -f /etc/redhat-release ]
then
	echo "Using si_prepareclient."
	si_prepareclient --server $PRIMARY_IP --quiet || { echo "Error in si_prepareclient" && exit -1; }
else
	echo "Using /usr/sbin/si_prepareclient."
	/usr/sbin/si_prepareclient --server $PRIMARY_IP --quiet || { echo "Error in /usr/sbin/si_prepareclient" && exit -1; }
fi

export EXCLUDED_FILES_FILE=/usr/share/haoscar/excludedfiles

if ! grep "$IMAGE_DIR" $EXCLUDED_FILES_FILE >/dev/null 2>&1; then
	echo "$IMAGE_DIR" >> $EXCLUDED_FILES_FILE;
fi

echo "Getting the image";
if [ ! -f /etc/redhat-release ]
then
	echo "Using si_getimage."
	si_getimage --golden-client $PRIMARY_IP --image $IMAGE_NAME --post-install reboot --exclude-file $EXCLUDED_FILES_FILE --directory $IMAGE_DIR --ip-assignment static --quiet || { echo "Error in si_getimage" && exit -1; }
else
	echo "Using /usr/sbin/si_getimage."
	/usr/sbin/si_getimage --golden-client $PRIMARY_IP --image $IMAGE_NAME --post-install reboot --exclude-file $EXCLUDED_FILES_FILE --directory $IMAGE_DIR --ip-assignment static --quiet || { echo "Error in /usr/sbin/si_getimage" && exit -1; }
fi

# Now, we have to alter the system configuration of the image
echo "Configuring the image ...";
if [ ! -f /etc/redhat-release ]
then
	echo "Using chroot."
	chroot $IMAGE_DIR/$IMAGE_NAME config-image.sh
else
	echo "Using /usr/sbin/chroot." 
	/usr/sbin/chroot $IMAGE_DIR/$IMAGE_NAME config-image.sh
fi

# NOTE: If ufw is active, we have to add a rule to allow rsync port
echo "Start the systemimager-server-rsyncd service"
if [ ! -f /etc/redhat-release ]
then
	echo "Using service to start."
	service systemimager-server-rsyncd start
else
	echo "Using /sbin/service to start."
	/sbin/service systemimager-server-rsyncd start
fi

echo "Make bootserver";
if [ ! -f /etc/redhat-release ]
then 
	echo "Using si_mkbootserver."
	si_mkbootserver -f --interface=$HA_ETH --localdhcp=y --pxelinux=/usr/lib/syslinux/pxelinux.0
else
	echo "Using /usr/sbin/si_mkbootserver."
	/usr/sbin/si_mkbootserver -f --interface=$HA_ETH --localdhcp=y --pxelinux=/usr/lib/syslinux/pxelinux.0
fi
# Hey, you may have to manually edit the dhcp configuration file
# instead of using the interactive si_mkdhcpserver
# Then, don't forget to restart the dhcp server
# NOTE: The following line is for ubuntu only

echo "Configuring DHCP ...";
# Executes download commands that are slightly different if a redhat distrobution is detected.
if [ ! -f /etc/redhat-release ]
then
	dhcp_conf="/etc/dhcp3/dhcpd.conf";
else
	dhcp_conf="/etc/dhcpd.conf";
fi
bak $dhcp_conf;

gen-dhcpd-conf.pl --primary-ip $PRIMARY_IP \
	--secondary-ip $SECONDARY_IP \
	--netmask $MASK \
	--subnet $SUBNET > $dhcp_conf

# Executes download commands that are slightly different if a redhat distrobution is detected.
if [ ! -f /etc/redhat-release ]
then
	service dhcp3-server restart
else 
	/etc/init.d/dhcpd restart
fi


echo "Configuring cluster.xml ...";
# Then edit the file /etc/systemimager/cluster.xml
#  defining your cluster (well ... just primary head as image server
#  and secondary head as client) 
# Then, run the following command

cluster_xml="/etc/systemimager/cluster.xml";
bak $cluster_xml;

gen-cluster-xml.pl --primary-hostname $PRIMARY_HOSTNAME \
	--secondary-hostname $SECONDARY_HOSTNAME \
	--image-name $IMAGE_NAME \
	--image-group-name $GROUP_NAME \
	> $base_name

si_clusterconfig -u
# This is not working
#  |
#  |
#  v
#si_mkclientnetboot --netboot --clients $SECONDARY_IP --flavor $IMAGE_NAME
#
# si_mkclientnetboot will need info from cluster.xml
# so, wee need to put secondary ip address in /etc/hosts
# for this to work
#

if [ ! -f /etc/redhat-release ]
then
	si_mkclientnetboot --netboot --clients $SECONDARY_HOSTNAME --flavor $IMAGE_NAME
	# Executes download commands that are slightly different if a redhat distrobution is detected.
else
	/usr/sbin/si_mkclientnetboot --netboot --client $SECONDARY_HOSTNAME --flavor $IMAGE_NAME
fi

if [ ! -f /etc/redhat-release ]
then
	if service systemimager-server-rsyncd status; then
		service systemimager-server-rsyncd restart; 
	else
		service systemimager-server-rsyncd start; 
	fi
else
	if /etc/init.d/systemimager-server-rsyncd status;
	then
		/etc/init.d/systemimager-server-rsyncd restart;
	else
		/etc/init.d/systemimager-server-rsyncd start;
	fi
fi	

exit 0;


