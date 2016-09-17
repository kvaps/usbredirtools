#!/bin/bash
ACTION=$1
VM=one-$2
TEMPLATE=$3
HOSTNAME=($(echo $TEMPLATE | base64 -d  | grep -oP '(?<=<HOSTNAME>).*(?=</HOSTNAME>)' | tail -n1))
USBREDIRS=($(echo $TEMPLATE | base64 -d | grep -oP 'USBREDIR[0-9]+><!\[CDATA\[[a-zA-Z0-9_:.-]*' | grep -oP '[a-zA-Z0-9_:.-]*$'))
LASTNUM=$(virsh --connect=qemu+ssh://$HOSTNAME/system qemu-monitor-command --hmp $VM 'info chardev' | grep -Po -m1 '(?<=charredir)[0-9]*')

for USBREDIR in ${USBREDIRS[@]}; do
    case $ACTION in
        connect)
            NUM=$(($LASTNUM+1))
            CHARDEV_HOST=$(echo $USBREDIR | grep -Po '^[^:]+')
            CHARDEV_PORT=$(echo $USBREDIR | grep -Po '[^:]+$')
            CHARDEV="socket,id=charredir${NUM},host=${CHARDEV_HOST},port=${CHARDEV_PORT}"
            DEVICE="usb-redir,chardev=charredir${NUM},id=redir${NUM},bus=usb.0"

            virsh --connect=qemu+ssh://$HOSTNAME/system qemu-monitor-command --hmp $VM "chardev-add $CHARDEV" 
            virsh --connect=qemu+ssh://$HOSTNAME/system qemu-monitor-command --hmp $VM "device_add $DEVICE"

            LASTNUM=$NUM
        ;;
        disconnect)
            NUM=$(virsh --connect=qemu+ssh://$HOSTNAME/system qemu-monitor-command --hmp $VM 'info chardev' | grep $USBREDIR | grep -Po -m1 '(?<=charredir)[0-9]*')

            virsh --connect=qemu+ssh://$HOSTNAME/system qemu-monitor-command --hmp $VM "device_del redir${NUM}"
        ;;
    esac
done
