case $1 in
    "--proxmox" ) BACKEND='proxmox' ;;
    *           ) BACKEND='libvirt' ;;
esac

function qm_monitor {
    local VM="$1"
    local COMMAND="$2"

    case $BACKEND in
        'libvirt' )
            virsh qemu-monitor-command --hmp "$VM" "$COMMAND"
        ;;
        'proxmox' )
            expect -c 'log_user 0; spawn /usr/sbin/qm monitor '"$VM"'; send "'"$COMMAND"'\r"; expect "qm>"; log_user 1; expect "qm>"; log_user 0; send "quit\r"; expect eof;' | head -n -1
        ;;
    esac
}

chardevs=($(ps aux | grep -oP '(?<=\-chardev )[^ ]*host=([0-9]+\.?){4}[^ ]*'))

for i in ${chardevs[@]}; do
    CHARDEV="$i"
    CHARDEV_ID=$(echo "$CHARDEV" | grep -oP '(?<=id=)[^,]*')

    case $BACKEND in
        'libvirt' ) VM=$(ps aux | grep "$CHARDEV" | grep -oP '(?<=\-name )[^ ]*') ;;
        'proxmox' ) VM=$(ps aux | grep "$CHARDEV" | grep -oP '(?<=\-id )[0-9]*') ;;
    esac

    CHARDEV_MONIT=$(qm_monitor "$VM" 'info chardev' | grep "^${CHARDEV_ID}")

    # Check status
    if [ -z "$CHARDEV_MONIT" ] || [ $(echo "$CHARDEV_MONIT" | grep -q 'disconnected') ]; then
        CHARDEV_STATUS='disconnected'
    else
        CHARDEV_STATUS='connected'
    fi

    if [ "$CHARDEV_STATUS" == "disconnected" ]; then
        DEVICE=$(ps aux | grep "$CHARDEV" | grep -oP '(?<=\-device )[^ ]*'$CHARDEV_ID'[^ ]*')
        DEVICE_ID=$(echo "$DEVICE" | grep -oP '(?<=id=)[^,]*')

        # Remove usb device
        qm_monitor "$VM" "device_del $DEVICE_ID"

        # Create chardev and save output
        CHARDEV_ADD_OUTPUT="(
            qm_monitor "$VM" "chardev-add $CHARDEV"
        )"

        # Check if chardev-add operation contains duplucate error
        if $(echo $CHARDEV_ADD_OUTPUT | grep -q "Duplicate ID"); then
            # Increase CHARDEV and DEVICE
            local CHARDEV_ID_NAME=$(echo "$CHARDEV_ID" | sed 's/[0-9]*$//')
            local CHARDEV_ID_NUM=$(echo "$CHARDEV_ID" | grep -oP '[0-9]*$')
            CHARDEV=$(echo "$CHARDEV" | sed "s|id=${CHARDEV_ID_NAME}${CHARDEV_ID_NUM}|id=${CHARDEV_ID_NAME}$((CHARDEV_ID_NUM+1))|g")
            local DEVICE_ID_NAME=$(echo "$DEVICE_ID" | sed 's/[0-9]*$//')
            local DEVICE_ID_NUM=$(echo "$DEVICE_ID" | grep -oP '[0-9]*$')
            DEVICE=$(echo "$DEVICE" | sed -r -e "s|chardev=${CHARDEV_ID_NAME}${CHARDEV_ID_NUM}|chardev=${CHARDEV_ID_NAME}$((CHARDEV_ID_NUM+1))|g" \
                                             -e "s|id=${DEVICE_ID_NAME}${DEVICE_ID_NUM}|id=${DEVICE_ID_NAME}$((DEVICE_ID_NUM+1))|g"
            )
        fi

        # Add usb device
        qm_monitor "$VM" "device_add $DEVICE"

    fi 
done
