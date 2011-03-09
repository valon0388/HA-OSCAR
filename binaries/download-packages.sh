#!/bin/bash
# This is for debian-based only
# NOTE:
#  This downloading script is for testing purposes only
# The real package should handle this for the users...

#Determines the architecture type of the host system
if [ $HOSTTYPE 	!= "x86_64" ]
then
	ARCH="i386"
else
	ARCH="x86_64"
fi

echo "$ARCH Distrobution detected....."

# Executes download commands that are slightly different if a redhat distrobution is detected.
if [ ! -f /etc/redhat-release ]
then
	echo "Deb based distrobution detected....."
	./install -v --download-only --tag stable --directory . systemconfigurator \
	systemimager-client systemimager-common /
	systemimager-boot-"$ARCH"-standard systemimager-initrd-template-"$ARCH" \
	systemimager-client systemimager-common \
	systemimager-"$ARCH"boot-standard systemimager-"$ARCH"initrd_template \
	systemimager-server
