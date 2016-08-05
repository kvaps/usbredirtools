chardevs=($(ps aux | grep -oP '(?<=\-chardev )[^ ]*host=([0-9]+\.?){4}[^ ]*'))

for i in ${chardevs[@]}; do
    CHARDEV="$i"
    CHARDEV_ID=$(echo "$CHARDEV" | grep -oP '(?<=id=)[^,]*')
    NAME=$(ps aux | grep "$CHARDEV" | grep -oP '(?<=\-name )[^ ]*')
    DEVICE=$(ps aux | grep "$CHARDEV" | grep -oP '(?<=\-device )[^ ]*'$CHARDEV_ID'[^ ]*')
    DEVICE_ID=$(echo "$DEVICE" | grep -oP '(?<=id=)[^,]*')

    if $(virsh qemu-monitor-command --hmp $NAME 'info chardev' | grep "^${CHARDEV_ID}" | grep -q 'disconnected'); then
        CHARDEV_STATUS='disconnected'
    else
        CHARDEV_STATUS='connected'
    fi

    if [ "$CHARDEV_STATUS" == "disconnected" ]; then
        virsh qemu-monitor-command --hmp $NAME "device_del $DEVICE_ID"
        virsh qemu-monitor-command --hmp $NAME "chardev-add $CHARDEV"
        virsh qemu-monitor-command --hmp $NAME "device_add $DEVICE"
    fi 
done
