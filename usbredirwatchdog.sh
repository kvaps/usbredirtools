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

    if $(qm_monitor "$VM" 'info chardev' | grep "^${CHARDEV_ID}" | grep -q 'disconnected'); then
        CHARDEV_STATUS='disconnected'
    else
        CHARDEV_STATUS='connected'
    fi

    if [ "$CHARDEV_STATUS" == "disconnected" ]; then
        DEVICE=$(ps aux | grep "$CHARDEV" | grep -oP '(?<=\-device )[^ ]*'$CHARDEV_ID'[^ ]*')
        DEVICE_ID=$(echo "$DEVICE" | grep -oP '(?<=id=)[^,]*')
        qm_monitor "$VM" "device_del $DEVICE_ID"
        qm_monitor "$VM" "chardev-add $CHARDEV"
        qm_monitor "$VM" "device_add $DEVICE"
    fi 
done
