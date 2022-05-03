# usbip

ZIP-Download: [Release-Page](https://github.com/psct/usbip/releases)

## German

Dieses Repository enthält Dateien zu einem Artikel in c't 11/2022, S. 66 (USB-Streckbank mit Raspi, USB über LAN und WLAN verlängern: USB/IP). Die u.g. englischen Hinweise finden Sie im Artikel – der Artikel versäumt allerdings den Hinweis, die Befehle als root oder mit sudo auszuführen. Er sei hiermit nachgereicht.

## English

systemd-Units for USB/IP - let a Raspberry Pi (or any Linux host) share USB devices on a network by using Linux kernel components named "USB/IP". The units have to be copied to server and client and registered with `systemctl daemon-reload`. 

The server starts sharing devices after their USB vendor and device IDs have been added to /etc/udev/rules.d/90-usbip.rules and those rules have been put in place by calling `udevadm control --reload-rules && sudo udevadm trigger` (all commands have to be prefixed with sudo or be called as root user).

On the client side you (as user root or with sudo prefixed) have to connect to the shared devices by calling `systemctl enable usbip@srv:03f0:3d17` and `systemctl start usbip@srv:03f0:3d17` – "srv" may be a valid host name or an IPv4/IPv6 address. "03f0:3d17" are vendor and device ID for a HP laser printer placed in mentioned 90-usbip.rules.

Beware: Those systemd units and udev rules only support sharing one device with the same vendor and device ID. Furthermore they don't try to unload the whole stack on inactivity (no device shared) because that led to kernel panics while trying to do so.

The units and rules have been tested on Pi OS Buster, Debian Buster and Linux Mint 20.3 - they should work with minor modifications on any systemd based distribution.

