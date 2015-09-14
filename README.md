usbredirtools
=============

Server install
--------------
```
git clone https://github.com/kvaps/usbredirtools
cd usbredirtools
cp usbredirserver\@.service /etc/systemd/system/usbredirserver\@.service
vim /etc/udev/rules.d/99-usb-serial.rules
```
```
ACTION=="add", ATTR{serial}=="11C130317234004B", RUN+="/bin/bash -c 'PORT=4000; echo -e "BUS=$attr{busnum}\\nDEV=$attr{devnum}" > /var/lib/usbredirserver/$PORT; service usbredirserver@$PORT restart'"
```

Hypervisor install
------------------
```
git clone https://github.com/kvaps/usbredirtools
cd usbredirtools
cp usbreconnect.sh /bin/usbreconnect.sh
groupadd usbredir
useradd usbuser -m -d /home/usbuser -g usbredir
passwd usbuser
%usbredir ALL = NOPASSWD: /bin/usbreconnect.sh
```

Windows-client install
----------------------

  - create file: usbreconnect.bat
```
plink.exe usbuser@192.168.100.220 -pw PASSWORD /usr/bin/sudo /bin/usbreconnect.sh
```
