#!/bin/bash
# Copyright (C) 2012  Vincent Van der Kussen
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#

# process arguments
# -n = name
# -b = buildnumber
# -o = overwrite 
while getopts n:b:o opt ; do

case $opt in
		n) name=$OPTARG;;
		b) build=$OPTARG;;
		o) overwrite=yes;;
		?) echo="usage";
	exit 1;;
esac
done 

# set variables
vmname="$name-$build"		# define hostname and VM name
obuild=$((build-1))		# define old build (we assume build -1)
ovmname="$name-$obuild"		# old vmname with previous build


#overwrite function
if [ "$overwrite" = yes ]; then
	#also release the IP of the previous build in the DB
	sqlite3 iplist.db "update ip set status=0,hostname='""' where hostname='"$ovmname"';"
	virsh --connect qemu+ssh://root@192.168.13.172/system destroy $ovmname
	virsh --connect qemu+ssh://root@192.168.13.172/system undefine $ovmname
	odiskname="`virsh --connect qemu+ssh://root@192.168.13.172/system vol-list default |grep "$ovmname" | awk '{print $1}'`"
	virsh --connect qemu+ssh://root@192.168.13.172/system vol-delete $odiskname
fi


# get the status of the VM. If it doesn't exist return should be empty. 
vmstatus="`virsh --connect qemu+ssh://root@192.168.13.172/system list --all | grep "$vmname" | awk '{ print $3 }'`"


#check ip DB for unused ip address amd use the first freely available.
ipaddress=`sqlite3 iplist.db "select * from ip where status=0 limit 1;" | awk -F"|" '{print $2}'`

#mark the ip address as used and add the hostname
sqlite3 iplist.db "update ip set status=1,hostname='"$vmname"' where address='"$ipaddress"';"


#prepare kickstart file with dynamic content ( hostname, etc)
sed -i 's/--ip=[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}/--ip='$ipaddress'/g' scorpia01.ks
sed -i 's/--hostname=\(.\)*/--hostname='$vmname'/g' scorpia01.ks
scp scorpia01.ks root@192.168.13.173:/var/www/html/kicks







# detect status and perform the necessary action
case $vmstatus in
		running)
		  echo="VM with that name already exists and running Reinstallation begins..."
		  virsh --connect qemu+ssh://root@192.168.13.172/system destroy $vmname
		  virsh --connect qemu+ssh://root@192.168.13.172/system undefine $vmname
		  diskname="`virsh --connect qemu+ssh://root@192.168.13.172/system vol-list default |grep "$vmname" | awk '{print $1}'`"
		  virsh --connect qemu+ssh://root@192.168.13.172/system vol-delete $diskname
		  #this should become a function
		  virt-install --connect qemu+ssh://root@192.168.13.172/system -n $vmname -r 512 --disk pool=default,device=disk,bus=virtio,size=8 --network bridge=br0,model=virtio -l http://192.168.13.173/os -x "ks=http://192.168.13.173/kicks/scorpia01.ks"
		  vmstatus="`virsh --connect qemu+ssh://root@192.168.13.172/system list --all | grep "$vmname" | awk '{ print $3 }'`"
 		  while [ "$vmstatus" = running ]
 			do
 			vmstatus="`virsh --connect qemu+ssh://root@192.168.13.172/system list --all | grep "$vmname" | awk '{ print $3 }'`"
			sleep 60;
		  done
		;;
		shut)
		  echo="VM with that name already exists and shutdown Reinstallation begins..."
		  virsh --connect qemu+ssh://root@192.168.13.172/system undefine $vmname
		  diskname="`virsh --connect qemu+ssh://root@192.168.13.172/system vol-list default |grep "$vmname" | awk '{print $1}'`"
                  virsh --connect qemu+ssh://root@192.168.13.172/system vol-delete $diskname
		  virt-install --connect qemu+ssh://root@192.168.13.172/system -n $vmname -r 512 --disk pool=default,device=disk,bus=virtio,size=8 --network bridge=br0,model=virtio -l http://192.168.13.173/os -x "ks=http://192.168.13.173/kicks/scorpia01.ks"
                  vmstatus="`virsh --connect qemu+ssh://root@192.168.13.172/system list --all | grep "$vmname" | awk '{ print $3 }'`"
                  while [ "$vmstatus" = running ]
                         do
                         vmstatus="`virsh --connect qemu+ssh://root@192.168.13.172/system list --all | grep "$vmname" | awk '{ print $3 }'`"
                         sleep 60;
		  done
		;;	  
		*)
		  echo="Installing new VM"
		  virt-install --connect qemu+ssh://root@192.168.13.172/system -n $vmname -r 512 --disk pool=default,device=disk,bus=virtio,size=8 --network bridge=br0,model=virtio -l http://192.168.13.173/os -x "ks=http://192.168.13.173/kicks/scorpia01.ks"
 		  vmstatus="`virsh --connect qemu+ssh://root@192.168.13.172/system list --all | grep "$vmname" | awk '{ print $3 }'`"
                  while [ "$vmstatus" = running ]
                         do
                         vmstatus="`virsh --connect qemu+ssh://root@192.168.13.172/system list --all | grep "$vmname" | awk '{ print $3 }'`"
                         sleep 60;
                  done
	       ;;
esac


## put in comment to test the above

#if [ -z "$vmstatus" ];
#then
# install vm on the hypervisor
#virt-install --connect qemu+ssh://root@192.168.13.172/system -n $vmname -r 512 --disk pool=default,device=disk,bus=virtio,size=8 --network bridge=br0,model=virtio --mac=$mac --pxe 


#vmstatus="`virsh --connect qemu+ssh://root@192.168.13.172/system list --all | grep "$vmname" | awk '{ print $3 }'`"

#while [ "$vmstatus" = running ]
#do
#vmstatus="`virsh --connect qemu+ssh://root@192.168.13.172/system list --all | grep "$vmname" | awk '{ print $3 }'`"
#sleep 60;
#done



## if vm is running wait for shutdown (wait until)
#elif [ "$vmstatus" = "shut" ];
#vmstatus="`virsh --connect qemu+ssh://root@192.168.13.172/system remove $vmname`"

virsh -c qemu+ssh://root@192.168.13.172/system dumpxml $vmname > /tmp/tempxml

sed -i "/dev='network'/d" /tmp/tempxml					#remove the PXE boot option from the vm's xml 

#sed  -i "/dev='hd'/i \ <boot dev='network' />" /tmp/tempxml		#insert PXE boot 

virsh -c qemu+ssh://root@192.168.13.172/system define /tmp/tempxml	#redefine the VM based on the adjusted XML
virsh -c qemu+ssh://root@192.168.13.172/system start "$vmname"		#start the vm without pxe

#else echo "vm is not shutdown"
#fi
