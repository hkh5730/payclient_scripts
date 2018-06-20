#!/bin/bash
dirs=(/home/commaai/Klas/working_images /home/commaai/Klas/working_images_original)

percent=`df -k | grep overlayroot | awk '{print int($5)}'`
for dir in ${dirs[@]}
    do
        if [ -d ${dir} ]; then
            find ${dir} -mtime +15 -name "*.*" -exec rm -rf {} \;
            if [ $percent -ge 90 ]; then
                rm -rf ${dir}/*
            fi
        fi
    done

exit 0
