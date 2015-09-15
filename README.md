usbredirtools
=============

### USB Server install
```
# curl -o /etc/systemd/system/usbredirserver\@.service https://raw.githubusercontent.com/kvaps/usbredirtools/master/usbredirserver%40.service
# mkdir /var/lib/usbredirserver/
# vim /etc/udev/rules.d/99-usb-serial.rules
```
```
ACTION=="add", ATTR{serial}=="11C130317234004B", RUN+="/bin/bash -c 'PORT=4000; echo -e BUS=$attr{busnum}\\nDEV=$attr{devnum} > /var/lib/usbredirserver/$PORT; systemctl restart usbredirserver@$PORT'"
```

### Hypervisor install (proxmox)
sudo and expect packages is required.
```
# curl -o /bin/usbreconnect.sh https://raw.githubusercontent.com/kvaps/usbredirtools/master/usbreconnect.sh
# chmod +x /bin/usbreconnect.sh 
# mkdir /var/lib/usbredirclient/
# groupadd usbredir
# useradd usbuser -m -d /home/usbuser -g usbredir
# passwd usbuser
# visudo
```
```
%usbredir ALL = NOPASSWD: /bin/usbreconnect.sh
```
```
# vim /etc/usbredirclient.conf
```
```
[usbtest]
100 = 192.168.100.95:4000
#100 = 192.168.100.95:4001
#[anotheruser]
#101 = 192.168.100.95:4002

```

### Windows-client install

  - create file: usbreconnect.bat
```
plink.exe usbuser@192.168.100.220 -pw PASSWORD /usr/bin/sudo /bin/usbreconnect.sh 100
```
*You can set no vmid as argument, then all devices will be reconnected for this user.*

**Using ssh-keys is true way!**
