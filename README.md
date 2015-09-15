usbredirtools
=============
These scripts help you passthrough many identical usb-devices (with the same vendorid:productid pair) for selected virtual machines, using [usbredir](http://www.spice-space.org/page/UsbRedir) protocol in daemon mode, without using spice.

### USB Server install
  - `curl -o /etc/systemd/system/usbredirserver\@.service https://raw.githubusercontent.com/kvaps/usbredirtools/master/usbredirserver%40.service`
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
ACTION=="add", ATTR{serial}=="11C130317234004B", RUN+="/bin/bash -c 'PORT=4000; echo -e BUS=$attr{busnum}\\nDEV=$attr{devnum} > /var/lib/usbredirserver/$PORT; systemctl restart usbredirserver@$PORT'"
# by phisical port
ACTION=="add", KERNEL=="3-2", RUN+="/bin/bash -c 'PORT=4000; echo -e BUS=$attr{busnum}\\nDEV=$attr{devnum} > /var/lib/usbredirserver/$PORT; systemctl restart usbredirserver@$PORT'"
```
  - `udevadm control --reload-rules`

### Hypervisor install (proxmox)
  - Install **sudo** and **expect** packages, it is required
  - `curl -o /bin/usbreconnect.sh https://raw.githubusercontent.com/kvaps/usbredirtools/master/usbreconnect.sh`
  - `chmod +x /bin/usbreconnect.sh`
  - `mkdir /var/lib/usbredirclient/`
  - `groupadd usbredir`
  - `useradd usbuser -m -d /home/usbuser -g usbredir`
  - `passwd usbuser`
  - `visudo`
```
%usbredir ALL = NOPASSWD: /bin/usbreconnect.sh
```
  - `vim /etc/usbredirclient.conf`
```
[usbtest]
100 = 192.168.100.95:4000
#100 = 192.168.100.95:4001
#[anotheruser]
#101 = 192.168.100.95:4002

```

#### qemu setup
  - `curl http://cgit.freedesktop.org/spice/qemu/plain/docs/ich9-ehci-uhci.cfg --create-dirs -o /etc/qemu/ich9-ehci-uhci.cfg`
  - add `-readconfig /etc/qemu/ich9-ehci-uhci.cfg` option to start command in virtual machine config file

### Windows-client install

  - create file: usbreconnect.bat
```
plink.exe usbuser@192.168.100.220 -pw PASSWORD /usr/bin/sudo /bin/usbreconnect.sh 100
```
*You can set no vmid as argument, then all devices will be reconnected for this user.*

**Using ssh-keys is true way!**
