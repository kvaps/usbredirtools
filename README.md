usbredirtools
=============
These scripts help you passthrough many identical usb-devices (with the same vendorid:productid pair) for selected virtual machines, using [usbredir](http://www.spice-space.org/page/UsbRedir) protocol in daemon mode, without using spice.

## USB Server install
  - Install **usbredirserver**, **inotifywait** and **fuser** packages, it is required
  - Install units and script:
```bash
curl -o /etc/systemd/system/usbredirserver\@.service https://raw.githubusercontent.com/kvaps/usbredirtools/master/usbredirserver%40.service
curl -o /etc/systemd/system/usbredirserver.service https://raw.githubusercontent.com/kvaps/usbredirtools/master/usbredirserver.service
curl -o /bin/usbredirserver.sh https://raw.githubusercontent.com/kvaps/usbredirtools/master/usbredirserver.sh
chmod +x /bin/usbredirserver.sh
```
  - `mkdir /var/lib/usbredirserver/`

#### Export usb-devce
  - run `lsusb`, find your device:
```
Bus 003 Device 090: ID 125f:c82a A-DATA Technology Co., Ltd. 
```
  - run `udevadm info -a -n /dev/bus/usb/003/090 | grep 'ATTR{serial}\|KERNEL[^S]'`
```
KERNEL=="3-2"
ATTR{serial}=="11C130317234004B"
```
  - `vim /etc/udev/rules.d/99-usb-serial.rules`
```
# by serial number
ACTION=="add", ATTR{serial}=="11C130317234004B", RUN+="/bin/bash -c 'PORT=4000; echo -e BUS=$attr{busnum}\\nDEV=$attr{devnum} > /var/lib/usbredirserver/$PORT'"
# by phisical port
ACTION=="add", KERNEL=="3-2", RUN+="/bin/bash -c 'PORT=4000; echo -e BUS=$attr{busnum}\\nDEV=$attr{devnum} > /var/lib/usbredirserver/$PORT'"
```
  - `udevadm control --reload-rules`
  - Start and enable usbredirserver service:
```bash
systemctl start usbredirserver.service
systemctl enable usbredirserver.service
```

## Hypervisor install (opennebula)

#### hook setup
  - `curl https://raw.githubusercontent.com/kvaps/usbredirtools/master/usbredir_hook.sh -o /var/lib/one/remotes/hooks/usbredir_hook.sh`
  - `chmod +x /var/lib/one/remotes/hooks/usbredir_hook.sh`
  - Declare hook in `/etc/one/oned.conf`:
```
VM_HOOK = [
    name      = "usbredir_connect",
    on        = "RUNNING",
    command   = "usbredir_hook.sh",
    arguments = "connect $ID $TEMPLATE" ]

VM_HOOK = [
    name      = "usbredir_disconnect",
    on        = "CUSTOM",
    state     = "ACTIVE",
    lcm_state = "SAVE_SUSPEND",
    command   = "usbredir_hook.sh",
    arguments = "disconnect $ID $TEMPLATE" ]
```
  - `systemctl restart opennebula` 

#### vm setup
  - add this code to your template, into kvm raw data section:
```xml
<devices>
<controller type='usb' index='0' model='ich9-ehci1'><address type='pci' domain='0x0000' bus='0x00' slot='0x08' function='0x7'/></controller>
<controller type='usb' index='0' model='ich9-uhci1'><master startport='0'/><address type='pci' domain='0x0000' bus='0x00' slot='0x08' function='0x0' multifunction='on'/></controller>
<controller type='usb' index='0' model='ich9-uhci2'><master startport='2'/><address type='pci' domain='0x0000' bus='0x00' slot='0x08' function='0x1'/></controller>
<controller type='usb' index='0' model='ich9-uhci3'><master startport='4'/><address type='pci' domain='0x0000' bus='0x00' slot='0x08' function='0x2'/></controller>
</devices>
```
  - add your usb devices into your template, like:
```
USBREDIR0="192.168.1.123:4000"
USBREDIR1="192.168.1.123:4001"
```


## Hypervisor install (proxmox)

#### qemu setup
  - `curl http://cgit.freedesktop.org/spice/qemu/plain/docs/ich9-ehci-uhci.cfg --create-dirs -o /etc/qemu/ich9-ehci-uhci.cfg`

#### vm setup
  - add this options to start command in virtual machine config file into `args` section:
```
  -readconfig /etc/qemu/ich9-ehci-uhci.cfg
  -chardev socket,id=charredir3,port=4000,host=192.168.1.123
  -device usb-redir,chardev=charredir3,id=redir3,bus=usb.0
```

## Watchdog service

Optionally, you may install usbredirwatchdog service on your hypervisors, it will reconnect the usb-devices if they was disconnected for some reasons.

It works this way:
Every `n` times, watchdog script calls `ps aux` and checks for running virtual machines with chadredir parameters.
After this watchdog script check the status of each chardev and reconnect it if it does not exist or disconnected.
The frequency is configured as the first script argument, by default it is 10 seconds.
Warning: this watchdog does not work with devices connected via opennebula hook.

#### Install instructions
  - For proxmox you need install **expect** package.
  - `curl https://raw.githubusercontent.com/kvaps/usbredirtools/master/usbredirwatchdog.sh -o /usr/local/bin/usbredirwatchdog.sh`
  - `chmod +x /usr/local/bin/usbredirwatchdog.sh`
  - `curl https://raw.githubusercontent.com/kvaps/usbredirtools/master/usbredirwatchdog.service -o /etc/systemd/system/usbredirwatchdog.service`
  - `systemctl enable usbredirwatchdog`
  - `systemctl start usbredirwatchdog`
