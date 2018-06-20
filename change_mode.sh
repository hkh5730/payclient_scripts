#!/bin/bash

change2ubuntu() {
    service PayClient stop
    service lightdm start
}

change2payclient() {
    service lightdm stop
    service PayClient start
}

case $1 in
    "ubuntu") change2ubuntu ;;
    "PayClient") change2payclient ;;
    *) echo "Invalid arg ..." ;;
esac
