auth --useshadow --enablemd5
bootloader --location=mbr
clearpart --all --initlabel
text
firstboot --disable
keyboard us
lang en_US
#url --url=$tree
#network --bootproto=dhcp --device=eth0 --onboot=on
network --bootproto=static --ip=192.168.13.181 --netmask=255.255.255.0 --gateway=192.168.13.1 --hostname=test-303
#reboot
poweroff
rootpw --iscrypted $1$ebFDZ$iOvFlrtXQmzhTbPUxna171
selinux --disabled
skipx
timezone --utc Europe/Brussels
install
zerombr yes
key --skip
#Disk partitioning information
part /boot --fstype ext3 --size=300
part swap --size=512
part pv.01 --size=1 --grow
volgroup vg_system pv.01
logvol / --vgname=vg_system --size=6000 --name=lv_root
%packages
-aspell
-aspell-en
-bleuz-util
-dhcpv6-client
-dosfstools
-firstboot-tui
-gpm
-irda-utils
-mgetty
-mozldap
-mtools
-pcmciautils
-rp-pppoe
-rsh
-telnet
-wireless-tools
-bleuz-gnome
-gtk2
-wireless-tools
vim-enhanced
%pre
%post
#ethtool -s eth0 speed 100 duplex full
