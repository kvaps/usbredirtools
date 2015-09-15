#!/bin/bash
USER=$(whoami)
VMID=$1
CONF=/etc/usbredirclient.conf

TOKENS=$(awk "/^\[${USER}/ {p=1; next}; /^\[/ {p=0}; p" $CONF | sed -e '/[;#].*/d' -e '/^$/d' | grep "^$VMID")

if [ "$TOKENS" = "" ]; then echo "no assigned USB"; exit 1; fi

IFS=$'\n'
for i in $TOKENS; do
    VMID=$(echo $i| awk -F'[=:]' '{print $1}')
    HOST=$(echo $i| awk -F'[=:]' '{print $2}')
    PORT=$(echo $i| awk -F'[=:]' '{print $3}')

    numberfile=/var/lib/usbredirclient/$VMID-$HOST:$PORT
    number=$(cat $numberfile)

    if ! [[ $number =~ ^-?[0-9]+$ ]] ; then
        echo 0 > $numberfile
        number=0
    fi
    newnumber=$[$number+1]
    echo $newnumber > $numberfile

    RUN=$(
    expect << EOF
spawn /usr/sbin/qm monitor ${VMID}
send "device_del usbredirdev${number}\r";
send "chardev-remove usbredirchardev${number}\r";
send "chardev-add socket,id=usbredirchardev${newnumber},port=${PORT},host=${HOST}\r";
send "device_add usb-redir,chardev=usbredirchardev${newnumber},id=usbredirdev${newnumber},bus=ehci.0,debug=4\r";
send "quit\r"; expect eof
EOF
    )

#echo "$RUN"
echo "$RUN" | grep 'Failed\|no such VM' && exit 1

done
