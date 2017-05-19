#!/bin/bash

UDEV_RULES_FILE="/etc/udev/rules.d/99-usb-serial.rules"
USBREDIR_ENV_PATH="/var/lib/usbredirserver"

PHYSICAL_KERNELS=($(cat $UDEV_RULES_FILE | grep -oP 'KERNEL=="[0-9-]*"' | grep -oP '[0-9-]*'))
USB_DEVICES=($(find /dev/bus/usb/ -type c))

for USB_DEVICE in ${USB_DEVICES[@]}; do
    USB_KERNEL=$(udevadm info -a -n $USB_DEVICE | grep -oP 'KERNEL=="[0-9-]*"' | grep -oP '[0-9-]*')
    for PHYSICAL_KERNEL in ${PHYSICAL_KERNELS[@]}; do
        if [ "$USB_KERNEL" == "$PHYSICAL_KERNEL" ]; then
            USB_BUS=$(udevadm info -a -n $USB_DEVICE | grep -oP 'ATTR{busnum}=="[0-9]*"' | grep -oP '[0-9]*')
            USB_DEV=$(udevadm info -a -n $USB_DEVICE | grep -oP 'ATTR{devnum}=="[0-9]*"' | grep -oP '[0-9]*')
            USB_TCPPORT=$(cat $UDEV_RULES_FILE | grep "KERNEL==\"$USB_KERNEL\"" | grep -oP 'PORT=[0-9]*' | grep -oP '[0-9]*')
            USBREDIR_ENV_FILE=${USBREDIR_ENV_PATH}/${USB_TCPPORT}
            echo BUS=$USB_BUS > $USBREDIR_ENV_FILE
            echo DEV=$USB_DEV >> $USBREDIR_ENV_FILE
        fi  
    done
done
