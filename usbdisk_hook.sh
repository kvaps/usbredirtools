#!/bin/bash
#
# VM_HOOK = [
#     name      = "usbdisk_connect",
#     on        = "RUNNING",
#     command   = "usbdisk_hook.sh",
#     arguments = "connect $ID $TEMPLATE" ]
# 
# VM_HOOK = [
#     name      = "usbdisk_disconnect",
#     on        = "CUSTOM",
#     state     = "ACTIVE",
#     lcm_state = "SAVE_SUSPEND",
#     command   = "usbdisk_hook.sh",
#     arguments = "disconnect $ID $TEMPLATE" ]
# 
# VM_HOOK = [
#     name      = "usbdisk_disconnect",
#     on        = "CUSTOM",
#     state     = "ACTIVE",
#     lcm_state = "SAVE_MIGRATE",
#     command   = "usbdisk_hook.sh",
#     arguments = "disconnect $ID $TEMPLATE" ]

ACTION=$1
VM=one-$2
TEMPLATE=$3
HOSTNAME=($(echo $TEMPLATE | base64 -d  | grep -oP '(?<=<HOSTNAME>).*(?=</HOSTNAME>)' | tail -n1))
USBDISKS=($(echo $TEMPLATE | base64 -d | grep -oP 'USBDISK[0-9]+><!\[CDATA\[[0-9]*' | grep -oP '[0-9]*$'))
DEVICE_LETTERS=({z..a})
DEVICE_LETTER_NUM=0

echo  ${USBDISKS[@]}
for USBDISK_ID in ${USBDISKS[@]}; do
    USBDISK_SOURCE=$(oneimage show $USBDISK_ID --xml | grep -oP '(?<=SOURCE><!\[CDATA\[).*(?=\]\]></SOURCE>)')
    DEVICE_FILE=$(mktemp)
    DEVICE_LETTER=${DEVICE_LETTERS[DEVICE_LETTER_NUM]}
    echo -e "<disk type='file' device='disk'>\n  <source file='${USBDISK_SOURCE}'/>\n  <target dev='vd${DEVICE_LETTER}' removable='on' bus='usb'/>\n</disk>" >> $DEVICE_FILE 
    case $ACTION in
        connect)
            echo virsh --connect=qemu+ssh://10.10.100.31/system attach-device $VM $DEVICE_FILE
            virsh --connect=qemu+ssh://$HOSTNAME/system attach-device $VM $DEVICE_FILE
        ;;
        disconnect)
            virsh --connect=qemu+ssh://$HOSTNAME/system detach-device $VM $DEVICE_FILE
        ;;
    esac
    rm -f $DEVICE_FILE
    DEVICE_LETTER_NUM=$((DEVICE_LETTER_NUM+1))
done
