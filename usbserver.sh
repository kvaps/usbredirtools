#!/bin/bash
port=$1
busdev=$2
pidfile=/var/run/usb-${port}.pid

KILL(){
    fuser -k $port/tcp
}

RUN(){
    until $(usbredirserver -p $port $busdev); do RUN; done
}

echo $$ > $pidfile
trap '{ rm -f $pidfile; KILL; exit 0; }' EXIT

KILL
RUN
