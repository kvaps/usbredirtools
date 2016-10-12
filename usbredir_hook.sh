usbredir_hook.sh
#!/bin/bash
#
# VM_HOOK = [
#     name      = "usbredir_connect",
#     on        = "RUNNING",
#     command   = "usbredir_hook.sh",
#     arguments = "connect $ID $TEMPLATE" ]
# 
# VM_HOOK = [
#     name      = "usbredir_disconnect",
#     on        = "CUSTOM",
#     state     = "ACTIVE",
#     lcm_state = "SAVE_SUSPEND",
#     command   = "usbredir_hook.sh",
#     arguments = "disconnect $ID $TEMPLATE" ]
# 
# VM_HOOK = [
#     name      = "usbredir_disconnect",
#     on        = "CUSTOM",
#     state     = "ACTIVE",
#     lcm_state = "SAVE_MIGRATE",
#     command   = "usbredir_hook.sh",
#     arguments = "disconnect $ID $TEMPLATE" ]

ACTION=$1
VM=one-$2
TEMPLATE=$3
HOSTNAME=($(echo $TEMPLATE | base64 -d  | grep -oP '(?<=<HOSTNAME>).*(?=</HOSTNAME>)' | tail -n1))
USBREDIRS=($(echo $TEMPLATE | base64 -d | grep -oP 'USBREDIR[0-9]+><!\[CDATA\[[a-zA-Z0-9_:.-]*' | grep -oP '[a-zA-Z0-9_:.-]*$'))

case $ACTION in
    connect)

        ssh $HOSTNAME <<EOT
LASTNUM=\$(virsh --connect=qemu:///system qemu-monitor-command --hmp $VM 'info chardev' | tr -d $'\\r' | grep -Po -m1 '(?<=charredir)[0-9]*')

for USBREDIR in ${USBREDIRS[@]}; do
     NUM=\$((\$LASTNUM+1))
     CHARDEV_HOST=\$(echo \$USBREDIR | grep -Po '^[^:]+')
     CHARDEV_PORT=\$(echo \$USBREDIR | grep -Po '[^:]+$')
     CHARDEV="socket,id=charredir\${NUM},host=\${CHARDEV_HOST},port=\${CHARDEV_PORT}"
     DEVICE="usb-redir,chardev=charredir\${NUM},id=redir\${NUM},bus=usb.0"

     virsh --connect=qemu:///system qemu-monitor-command --hmp $VM "chardev-add \$CHARDEV" 
     virsh --connect=qemu:///system qemu-monitor-command --hmp $VM "device_add \$DEVICE"

     LASTNUM=\$NUM
done
EOT

    ;;
    disconnect)

       ssh $HOSTNAME <<EOT
LASTNUM=\$(virsh --connect=qemu:///system qemu-monitor-command --hmp $VM 'info chardev' | tr -d $'\\r' | grep -Po -m1 '(?<=charredir)[0-9]*')

for USBREDIR in ${USBREDIRS[@]}; do
    NUM=\$(virsh --connect=qemu:///system qemu-monitor-command --hmp $VM 'info chardev' | grep \$USBREDIR | tr -d $'\\r' | grep -Po -m1 '(?<=charredir)[0-9]*')
    virsh --connect=qemu:///system qemu-monitor-command --hmp $VM "device_del redir\${NUM}"
done
EOT
    ;;
esac
