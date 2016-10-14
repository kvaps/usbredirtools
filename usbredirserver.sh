#!/bin/bash

DATADIR=/var/lib/usbredirserver

services() {
    echo $(ls -1 $DATADIR | grep -P '^[0-9]*' | sed -e 's/^/usbredirserver@/' -e 's/$/.service/')
}
start() {
    echo Starting services:
    IFS=' ' services

    systemctl start `services`
}
stop() {
    echo
    echo Stoping services:
    IFS=' ' services

    systemctl stop `services`
}
watch() {
    local PORT=$(inotifywait -e modify $DATADIR 2> /dev/null | grep -oP '(?<=MODIFY )[0-9]*')
    echo
    echo Restarting: usbredirserver@$PORT.service 
    systemctl restart usbredirserver@$PORT.service
    watch
}

trap stop EXIT
start
watch
