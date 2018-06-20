#!/bin/bash
LOGFILE="/var/log/recovery.log"

DEST_PATHS="/overlayfs/data-rw"
SOURCE_SIZE="0"
SNAPSHOT_DIR="/overlayfs/data-rw/snapshotbackup"
SNAPSHOT_VERSION=0
writelog () {
	if [ "$2" = "notime" ]
	then
		echo "                    $1" >> $LOGFILE
	else
		echo "$(date "+%Y-%m-%d %H:%M:%S")" "$1" >> $LOGFILE
	fi
}

errorexit () {
	echo "ERROR $1"
	writelog "RECOVERY SYSTEM ABORTED with ERROR $errormessage" 
	exit	
}

for arg in $@
do
	if [ "${arg:0:1}" = "-" ] ; then
		if [ "$1" = "--version" ] || [ "$1" = "-v" ]; then
			SNAPSHOT_VERSION=$2
			shift
		fi
	fi
done

read -r -p "Do you confirm whether to restore snapshot.$SNAPSHOT_VERSION ? [Y/n] " input
case $input in
	[yY][eE][sS]|[yY])
		started="$(date "+%Y-%m-%d %H:%M:%S")"
		;;
	[nN][oO]|[nN])
		writelog "Exit restore snapshot"
		echo "Exit restore snapshot"
		exit 1
		;;
	*)
		writelog "Invalid input..., Aborted restore snapshot"
		echo "Invalid input..., Aborted restore snapshot"
		exit 1
		;;
esac

SNAPSHOT_PATH="$SNAPSHOT_DIR/snapshot.$SNAPSHOT_VERSION/overlay"

echo "$SNAPSHOT_PATH"

if [ ! -d "$SNAPSHOT_PATH" ]
then
    errorexit "snapshot version does not exist"
fi

echo "restore snapshot.$SNAPSHOT_VERSION started at $started"
writelog "restore snapshot.$SNAPSHOT_VERSION started at $started"
eval rsync -a --delete $SNAPSHOT_PATH $DEST_PATHS
echo "restore snapshot.$SNAPSHOT_VERSION completed at $(date "+%Y-%m-%d %H:%M:%S")"
writelog "restore snapshot.$SNAPSHOT_VERSION completed at $(date "+%Y-%m-%d %H:%M:%S")"

read -r -p "Are You Sure Reboot System ? [Y/n] " parm
case $parm in
	[yY][eE][sS]|[yY])
		;;
	[nN][oO]|[nN])
		exit 1
		;;
esac
reboot
