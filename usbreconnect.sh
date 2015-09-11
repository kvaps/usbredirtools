#!/bin/bash
expect << EOF
spawn /usr/sbin/qm monitor 80230
send "device_del usbredirdev1\r";
send "chardev-remove usbredirchardev1\r";
send "chardev-add socket,id=usbredirchardev1,port=4000,host=192.168.100.95\r";
send "device_add usb-redir,chardev=usbredirchardev1,id=usbredirdev1,bus=ehci.0,debug=4\r";
send "quit\r"; expect eof
EOF
