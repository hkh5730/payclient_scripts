#!/bin/bash

FACTORY_SYSTEM_INFO="/overlayfs/system-ro/factory_info.txt"
DATA_RW="/overlayfs/data-rw"
RESTORE_FACTORY_ALL="no"
WARM_MSG="Do you confirm whether to factory data reset except for /home/commaai dir?"

for arg in $@
do
	if [ "${arg:0:1}" = "-" ] ; then
		if [ "$1" = "-all" ]; then
			RESTORE_FACTORY_ALL="yes"
			WARM_MSG="Do you confirm whether to factory all data reset?"
		fi
	fi
done

read -r -p "$WARM_MSG [Y/n] " input
case $input in
	[yY][eE][sS]|[yY])
	    echo "Enrer factory data reset!"
		;;
	[nN][oO]|[nN])
		echo "Exit factory data reset!"
        exit 1
	    ;;
    *)
        echo "Invalid input..."
        exit 1
        ;;
esac

pstatus_str=$(service PayClient status | grep "running")
if [[ $pstatus_str =~ "running" ]]
then
    echo "Stop PayClient service"
    service PayClient stop
else
    echo "PayClient already stop"
fi

if [ "$RESTORE_FACTORY_ALL" = "yes" ]
then
	if [ -f "$FACTORY_SYSTEM_INFO" ]
	then
    	rm -rf $DATA_RW/*
	fi
else
	if [ -d "$DATA_RW/snapshotbackup" ]
	then
		rm -rf $DATA_RW/snapshotbackup
	fi
		
	if [ -d "$DATA_RW/overlay" ]
	then
		for dir in `ls $DATA_RW/overlay`
		do
			if [ "$dir" = "home" ]
			then
				for xdir in `ls $DATA_RW/overlay/$dir`
				do
					if [ "$xdir" != "commaai" ]
					then
						rm -rf $DATA_RW/overlay/$dir/$xdir
					fi
				done
			else
				rm -rf $DATA_RW/overlay/$dir
			fi
		done
	fi
fi
reboot

exit 0
