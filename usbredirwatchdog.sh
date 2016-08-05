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
    CHARDEV_HOST=$(echo "$CHARDEV" | grep -oP '(?<=host=)[^,]*')
    CHARDEV_PORT=$(echo "$CHARDEV" | grep -oP '(?<=port=)[0-9]*')

    case $BACKEND in
        'libvirt' ) VM=$(ps aux | grep "$CHARDEV" | grep -oP '(?<=\-name )[^ ]*') ;;
        'proxmox' ) VM=$(ps aux | grep "$CHARDEV" | grep -oP '(?<=\-id )[0-9]*') ;;
    esac

    CHARDEV_MONIT=$(qm_monitor "$VM" 'info chardev' | grep "${CHARDEV_HOST}:${CHARDEV_PORT}")

    # Check status
    if [ -z "$CHARDEV_MONIT" ]; then
        CHARDEV_STATUS='not exist'
    elif $(echo "$CHARDEV_MONIT" | grep -q 'disconnected'); then
        CHARDEV_STATUS='disconnected'
    else
        CHARDEV_STATUS='connected'
    fi

    if [ "$CHARDEV_STATUS" != "connected" ]; then

        echo "USB ${CHARDEV_HOST}:${CHARDEV_PORT} $CHARDEV_STATUS in $VM vm."

        DEVICE=$(ps aux | grep "$CHARDEV" | grep -oP '(?<=\-device )[^ ]*'$CHARDEV_ID'[^ ]*')
        DEVICE_ID=$(echo "$DEVICE" | grep -oP '(?<=id=)[^,]*')

        if [ "$CHARDEV_STATUS" == "disconected" ]; then
            # Remove usb device
            qm_monitor "$VM" "device_del $DEVICE_ID"
        fi

        # Create chardev and save output
        CHARDEV_ADD_OUTPUT="$(
            qm_monitor "$VM" "chardev-add $CHARDEV"
        )"

        # Check if chardev-add operation contains connection error
        if $(echo "$CHARDEV_ADD_OUTPUT" | grep -q "Failed to connect socket"); then
            qm_monitor "$VM" "chardev-remove $CHARDEV_ID"
        fi

        # Check if chardev-add operation contains duplucate error
        while $(echo "$CHARDEV_ADD_OUTPUT" | grep -q "Duplicate ID"); do
            RANDOM_NUM=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c8)
            CHARDEV_ID_OLD="${CHARDEV_ID}"
            CHARDEV_ID="$(echo ${CHARDEV_ID} | sed 's/_[A-Za-z0-9]\{8\}_$//')_${RANDOM_NUM}_"
            CHARDEV=$(echo "$CHARDEV" | sed "s|id=${CHARDEV_ID_OLD}|id=${CHARDEV_ID}|")
            DEVICE=$(echo "$DEVICE" | sed -r -e "s|chardev=${CHARDEV_ID_OLD}|chardev=${CHARDEV_ID}|g")

            # Create chardev and save output
            CHARDEV_ADD_OUTPUT="$(
                qm_monitor "$VM" "chardev-add $CHARDEV"
            )"

            # Check if chardev-add operation contains connection error
            if $(echo "$CHARDEV_ADD_OUTPUT" | grep -q "Failed to connect socket"); then
                qm_monitor "$VM" "chardev-remove $CHARDEV_ID"
            fi
        done

        # Add usb device
        qm_monitor "$VM" "device_add $DEVICE"

        echo "USB ${CHARDEV_HOST}:${CHARDEV_PORT} reconnected as $CHARDEV_ID in $VM vm."
    fi 
done
