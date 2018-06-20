#!/bin/bash

PRODUCT="Klas_NanWei"
LOGFILE="/var/log/factory_system.log"

RUNNING_FILE="/tmp/factory_system_running"
SYSTEM_RO_DIR="/overlayfs/system-ro"
DATA_RW_DIR="/overlayfs/data-rw/overlay"
FACTORY_SYSTEM_INFO="factory_info.txt"
SYSTEM_HOME="/home/commaai"
FORCE_FACTORY_SYSTEM="no"
ALL_FACTORY_SYSTEM="no"

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
	writelog "SET FACTORY SYSTEM ABORTED with ERROR $errormessage" 
	exit	
}

for arg in $@
do
	if [ "${arg:0:1}" = "-" ] ; then
		if [ "$1" = "-f" ]; then
			FORCE_FACTORY_SYSTEM="yes"
			shift
		elif [ "$1" = "-all" ] ; then
			ALL_FACTORY_SYSTEM="yes"
		fi
	fi
done

if [ "$FORCE_FACTORY_SYSTEM" = "no" ]
then
	if [ -f "$SYSTEM_RO_DIR/$FACTORY_SYSTEM_INFO" ]
	then
    	errorexit "factory info is alreadly exist, can't set again!!!!"
	fi
fi

read -r -p "Do you confirm whether to set up as factory system ? [Y/n] " input
case $input in
	[yY][eE][sS]|[yY])
		started="$(date "+%Y-%m-%d %H:%M:%S")"
		;;
	[nN][oO]|[nN])
        writelog "Exit set up factory system"
        echo "Exit set up factory system"
		exit 1
		;;
	*)
        writelog "Invalid input..., Aborted set up factory system"
        echo "Invalid input..., Aborted set up factory system"
		exit 1
		;;
esac

service PayClient stop

if [ -f "$RUNNING_FILE" ]
then
    errorexit "factory_system is currently running"
else
	echo "$(date "+%Y-%m-%d %H:%M:%S")" >$RUNNING_FILE
fi

set_up_data_factory() {

	if [ -d "$DATA_RW_DIR$SYSTEM_HOME/$PRODUCT/working_images" ]
	then
		rm -rf $DATA_RW_DIR$SYSTEM_HOME/$PRODUCT/working_images/*
	fi

	if [ -d "$DATA_RW_DIR$SYSTEM_HOME/$PRODUCT/working_images" ]
	then
		rm -rf $DATA_RW_DIR$SYSTEM_HOME/$PRODUCT/working_images/*
	fi

	HOME_SIZE="0"
	home_cur_size="$(du -sk "$DATA_RW_DIR$SYSTEM_HOME" 2>/dev/null |awk '{print $1}')"
	HOME_SIZE="$(echo $HOME_SIZE + $home_cur_size | bc)"
	writelog "home_cur_size = $home_cur_size"

	HOME_HUMANSIZE="${HOME_SIZE} K"
	if [ "$HOME_SIZE" -gt 1048576 ]
	then
		HOME_HUMANSIZE="$(echo $HOME_SIZE / 1048576 | bc) G"
	elif [ "$HOME_SIZE" -gt 1024 ]
	then
		HOME_HUMANSIZE="$(echo $HOME_SIZE / 1024 | bc) M"
	fi

	SYSTEM_RO_FREE="$(df -kP "$SYSTEM_RO_DIR" |grep "/" |awk '{print $4}')"
	SYSTEM_RO_FREE_H="$(df -kPh "$SYSTEM_RO_DIR" |grep "/" |awk '{print $4}')"

	if [ "$SYSTEM_RO_FREE" -lt "$HOME_SIZE" ]
	then
		errormessage="Free space on $SYSTEM_RO_DIR is $SYSTEM_RO_FREE_H. Total PayClient size $HOME_HUMANSIZE."
		errorexit "$errormessage"
	fi

	echo "Factory system started"
	echo "Total size of Data: $HOME_HUMANSIZE"

	mount -o remount,rw $SYSTEM_RO_DIR
	if [ $? -ne 0 ]
	then
    	errorexit "could not mount $SYSTEM_RO_DIR to rw"
	fi

	rsync -a --delete $SYSTEM_HOME/ $SYSTEM_RO_DIR$SYSTEM_HOME
	if [ $? -ne 0 ]
	then
    	errorexit "rsync $SYSTEM_HOME/ to $SYSTEM_RO_DIR$SYSTEM_HOME fail!!!!"
	fi

	ro_home_size="$(du -sk "$SYSTEM_RO_DIR$SYSTEM_HOME" 2>/dev/null |awk '{print $1}')"
	writelog "ro_home_size = $ro_home_size"

	touch  $SYSTEM_RO_DIR/$FACTORY_SYSTEM_INFO

	echo "Factory system started at $started
	Total size of PayClient APP: $HOME_HUMANSIZE" >$SYSTEM_RO_DIR/$FACTORY_SYSTEM_INFO

	if [ $ro_home_size -ge $home_cur_size ]
	then
		rm -rf $DATA_RW_DIR$SYSTEM_HOME/*
	fi
}

#if [ "$ALL_FACTORY_SYSTEM" = "no" ]
#then
	#set_up_data_factory
#else
#	set_up_all_factory
#fi
set_up_data_factory
rm $RUNNING_FILE
reboot
echo "Factory system completed"