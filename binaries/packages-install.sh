#!/bin/bash

if [ $HOSTTYPE != "x86_64" ]
then
	ARCH="i386"
else
	ARCH="x86_64"
fi

if [ ! -f /etc/redhat-release ]
then
	echo "Deb based distrobution detected....."

	aptitude install libappconfig-perl libxml-simple-perl mkisofs mtools atftpd atftp pxe grub dhcp3-server || exit 0

	ln -s /usr/bin/atftp /usr/bin/tftp
	dpkg -i systemconfigurator_*.deb
	dpkg -i systemimager-common_*.deb systemimager-boot-i386-standard_*.deb systemimager-server_*.deb
	dpkg -i systemimager-initrd-template-i386* systemimager-client_*
	
else
	echo "RPM based distrobution detected....."

	yum -y install perl-XML-Simple mkisofs mtools tftp-server tftp syslinux grub dhcp || exit 0

# libappconfig-perl can be found here
	wget http://sourceforge.net/projects/systemconfig/files/perl-AppConfig/1.52-4/perl-AppConfig-1.52-4.noarch.rpm/download
# atftpd
	rpm -ivh perl-AppConfig-*.rpm	

	rpm -ivh systemconfigurator-*.rpm
	rpm -ivh systemimager-common-*.rpm systemimager-"$ARCH"boot-standard-*.rpm systemimager-server-*.rpm
	rpm -ivh systemimager-"$ARCH"initrd_template-*.rpm systemimager-client-*.rpm
fi 




