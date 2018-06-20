#!/bin/bash
SNAPSHOT_COUNT=10
INFO_FILE="backup_info.txt"
RSYNC_ARGS="-a --protect-args"
LOGFILE="/var/log/snapshotbackup.log"

SOURCE_PATHS="/overlayfs/data-rw/overlay"
SOURCE_SIZE="0"
DEST_PATH="/overlayfs/data-rw/snapshotbackup"

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
	writelog "Backup ABORTED with ERROR $errormessage" 
	exit	
}

started="$(date "+%Y-%m-%d %H:%M:%S")"
writelog "LAUNCH"

cur_size="$(du -sk "$SOURCE_PATHS" 2>/dev/null |awk '{print $1}')"
SOURCE_SIZE="$(echo $SOURCE_SIZE + $cur_size | bc)"

if [ "$SOURCE_PATHS" == "" ]
then
	errorexit "No usable source paths"
fi

SOURCE_HUMANSIZE="${SOURCE_SIZE} K"
if [ "$SOURCE_SIZE" -gt 1048576 ]
then
	SOURCE_HUMANSIZE="$(echo $SOURCE_SIZE / 1048576 | bc) G"
elif [ "$SOURCE_SIZE" -gt 1024 ]
then
	SOURCE_HUMANSIZE="$(echo $SOURCE_SIZE / 1024 | bc) M"
fi
echo "Total size of sources: $SOURCE_HUMANSIZE"

if [ ! -d "$DEST_PATH" ]
then
    mkdir -p $DEST_PATH
fi

DEST_FREE="$(df -kP "$DEST_PATH" |grep "/" |awk '{print $4}')"
DEST_FREE_H="$(df -kPh "$DEST_PATH" |grep "/" |awk '{print $4}')"
if [ "$DEST_FREE" -lt "$SOURCE_SIZE" ]
then
	errormessage="Free space on $DEST_PATH is $DEST_FREE_H. Total source size $SOURCE_HUMANSIZE."
	errorexit "$errormessage"
fi

RUNFILE="SNAPSHOTBACKUP_IS_RUNNING"

if [ -f "$DEST_PATH/$RUNFILE" ];
then
	errormessage="Backup is currently running, start time $(cat $DEST_PATH/$RUNFILE). Runfile is $DEST_PATH/$RUNFILE"
	errorexit "$errormessage"
else
	echo "$(date "+%Y-%m-%d %H:%M:%S")" > $DEST_PATH/$RUNFILE
fi

let backup_zerocount=SNAPSHOT_COUNT-1


backup_dircount="$(ls -1 $DEST_PATH | grep "snapshot." | wc -l)"


if [ $backup_dircount -lt $SNAPSHOT_COUNT ]
then
	for ((i=0;i<=backup_zerocount;i++)) 
	do
		if [ ! -d "$DEST_PATH/snapshot.$i" ]
		then
			mkdir "$DEST_PATH/snapshot.$i"
		fi
	done
elif [ $backup_dircount -gt $SNAPSHOT_COUNT ]
then
	echo "WARNING: Counted more backup dirs than set number of snapshots. Exceeding dirs left untouched."
fi

echo -e "Backup started\nSOURCES:$SOURCE_PATHS\nDESTINATION:$DEST_PATH\n$SNAPSHOT_COUNT versions kept"
writelog "Backup STARTED to $DEST_PATH keeping $SNAPSHOT_COUNT snapshots" 
writelog "Sources: $SOURCE_PATHS" notime
writelog "Total source size: $SOURCE_HUMANSIZE, Space on destination: $DEST_FREE_H" notime

rm -rf $DEST_PATH/snapshot.$backup_zerocount

for ((  i = backup_zerocount;  i >=1;  i--  ))
do
	let PREV=i-1
	mv $DEST_PATH/snapshot.$PREV $DEST_PATH/snapshot.$i
done

eval rsync $RSYNC_ARGS --delete --link-dest=../snapshot.1 $SOURCE_PATHS  $DEST_PATH/snapshot.0/
rm -rf $DEST_PATH/snapshot.0/overlay/tmp


FILE_COUNT="$(find "$DEST_PATH"/snapshot.0/* -type f -newer "$DEST_PATH"/snapshot.1 -exec ls {} \; | wc -l)"

echo "Backup started at $started
Backup completed at $(date "+%Y-%m-%d %H:%M:%S")
Backup sources: $SOURCE_PATHS
Total size of sources: $SOURCE_HUMANSIZE, space on destination: $DEST_FREE_H
$FILE_COUNT files updated since last snapshot" > $DEST_PATH/snapshot.0/$INFO_FILE

CHANGED_DIRS="$(find "$DEST_PATH"/snapshot.0/* -type d -newer "$DEST_PATH"/snapshot.1 -exec ls -d1 {} \;)"
echo -e "\nUpdated files found in the following directories:\n\n$CHANGED_DIRS" >> $DEST_PATH/snapshot.0/$INFO_FILE

rm $DEST_PATH/$RUNFILE


for ((i=0;i<=backup_zerocount;i++)) 
do
	if [ -e "$DEST_PATH/snapshot.$i/$INFO_FILE" ]
	then
		touch -r "$DEST_PATH/snapshot.$i/$INFO_FILE" "$DEST_PATH/snapshot.$i"
	fi
done

echo "Backup completed."
writelog "Backup to $DEST_PATH COMPLETED $FILE_COUNT files updated."
echo "$(tail -n 10000 $LOGFILE)" > "$LOGFILE"

