#!/bin/bash
#
# VM_HOOK = [
#     name      = "time_restore",
#     on        = "RUNNING",
#     state     = "ACTIVE",
#     lcm_state = "BOOT_SUSPENDED",
#     command   = "time_restore.sh",
#     arguments = "$ID $TEMPLATE" ]

VM="one-$1"
ATTEMPT=12
TIMEOUT=5

TEMPLATE="$2"
HOSTNAME=($(echo $TEMPLATE | base64 -d | grep -oP '(?<=<HOSTNAME>).*(?=</HOSTNAME>)' | tail -n1))

until [[ $ATTEMPT == 0 ]]; do
    virsh --connect=qemu+ssh://$HOSTNAME/system domtime $VM --now && exit
    sleep $TIMEOUT
    ATTEMPT=$((ATTEMPT-1))
done
