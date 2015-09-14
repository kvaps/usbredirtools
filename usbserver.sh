#!/bin/bash
port=$1
busdev=$2

fuser -k $port/tcp

RUN=$(until $(usbredirserver -p $port $busdev); do $RUN; done)

echo $! > /var/run/usb-${port}.pid
RUN
