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

        # Create chardev and check output for duplicate error
        unset ATTEMPT
        while $(qm_monitor "$VM" "chardev-add $CHARDEV" | grep -q "Duplicate ID"); do
            ATTEMPT=$((ATTEMPT+1))
            CHARDEV_ID_OLD="${CHARDEV_ID}"
            CHARDEV_ID="$(echo ${CHARDEV_ID} | sed 's/a'$((ATTEMPT-1))'$//')a${ATTEMPT}"
            CHARDEV=$(echo "$CHARDEV" | sed "s|id=${CHARDEV_ID_OLD}|id=${CHARDEV_ID}|")
            DEVICE=$(echo "$DEVICE" | sed -r -e "s|chardev=${CHARDEV_ID_OLD}|chardev=${CHARDEV_ID}|g")
        done

        # Add usb device
        qm_monitor "$VM" "device_add $DEVICE"

    fi 
done
