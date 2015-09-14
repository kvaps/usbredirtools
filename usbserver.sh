#!/bin/bash
port=$1
busdev=$2
pidfile=/var/run/usb-${port}.pid

STOP(){
    fuser -k $port/tcp
}

CLEAN(){
    if [ -f $pidfile ]; then
        kill $(cat $pidfile)
    fi
}

START(){
    echo $$ > $pidfile
    until $(usbredirserver -p $port $busdev); do START; done
}

trap '{ STOP; rm -f $pidfile; exit 0; }' EXIT

CLEAN
STOP
START
