#!/bin/bash

boot_for_ubuntu() {
    if [ -f /etc/systemd/system/multi-user.target.wants/PayClient.service ]; then
        systemctl disable PayClient.service
        ln -fs /lib/systemd/system/lightdm.service /etc/systemd/system/display-manager.service
        reboot
    fi
}

boot_for_payclient() {
    if [ -f /etc/systemd/system/display-manager.service ]; then
        rm -rf /etc/systemd/system/display-manager.service
        systemctl enable PayClient.service
        reboot
    fi
}

case $1 in
    "ubuntu") boot_for_ubuntu ;;
    "PayClient") boot_for_payclient ;;
    *) echo "Invalid arg ..." ;;
esac