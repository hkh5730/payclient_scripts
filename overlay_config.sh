#!/bin/bash

SYSTEM_RO_DIR="/overlayfs/system-ro"

overlay_enable(){
	sed -i '$s#.*#overlayroot=device:dev=/dev/nvme0n1p4,recurse=0#' /etc/overlayroot.conf
}

overlay_disable(){
	sed -i '$s#.*#overlayroot=""#' $SYSTEM_RO_DIR/etc/overlayroot.conf
}

if [ -f  "$SYSTEM_RO_DIR/etc/overlayroot.conf" ]
then
	OVERLAYFS="enable"
else
	OVERLAYFS="disable"
fi

if [ "$1" = "enable" ]
then
	if [ "$OVERLAYFS" = "enable" ]
	then
		echo "overlay has alreadly enable overlay"
		exit 0
	fi
elif [ "$1" = "disable" ]
then
	if [ "$OVERLAYFS" = "disable" ]
	then
		echo "overlay has alreadly enable overlay"
		exit 0
	fi
else
	echo "Invalid arg ..."
	exit 0	
fi

if [ "$1" = "disable" ]
then
	mount -o remount,rw $SYSTEM_RO_DIR
	if [ $? -ne 0 ]
	then
    	echo "could not mount $SYSTEM_RO_DIR to rw"
		exit 1
	fi
fi

case $1 in
    "enable") overlay_enable ;;
    "disable") overlay_disable ;;
esac
reboot
