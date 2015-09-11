#!/bin/bash
vmid=80230
usbaddr=192.168.100.95
usbport=4000
numberfile=/tmp/usbredirunmber.txt

number=$(cat $numberfile)
if ! [[ $number =~ ^-?[0-9]+$ ]] ; then
    echo 0 > $numberfile
    number=0
fi
newnumber=$[$number+1]
echo $newnumber > $numberfile

RUN=$(
expect << EOF
spawn /usr/sbin/qm monitor ${vmid}
send "device_del usbredirdev${number}\r";
send "chardev-remove usbredirchardev${number}\r";
send "chardev-add socket,id=usbredirchardev${newnumber},port=${usbport},host=${usbaddr}\r";
send "device_add usb-redir,chardev=usbredirchardev${newnumber},id=usbredirdev${newnumber},bus=ehci.0,debug=4\r";
send "quit\r"; expect eof
EOF
)

#echo "$RUN"
echo "$RUN" | grep Failed && exit 1
