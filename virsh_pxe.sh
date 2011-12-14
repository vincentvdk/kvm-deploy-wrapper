#!/bin/bash
#
#
#
#
# process arguments
while getopts n:b: opt ; do

case $opt in
		n) name=$OPTARG;;
		b) build=$OPTARG;;
		?) echo="usage";
	exit 1;;
esac
done 

# set variables
vmname="$name-$build"
mac="52:54:00:f3:d5:10"

vmstatus="`virsh --connect qemu+ssh://root@192.168.13.172/system list --all | grep "$vmname" | awk '{ print $3 }'`"


if [ -z "$vmstatus" ];
then
# install vm on the hypervisor
virt-install --connect qemu+ssh://root@192.168.13.172/system -n $vmname -r 512 --disk pool=default,device=disk,bus=virtio,size=8 --network bridge=br0,model=virtio --mac=$mac --pxe 


vmstatus="`virsh --connect qemu+ssh://root@192.168.13.172/system list --all | grep "$vmname" | awk '{ print $3 }'`"

while [ "$vmstatus" = running ]
do
vmstatus="`virsh --connect qemu+ssh://root@192.168.13.172/system list --all | grep "$vmname" | awk '{ print $3 }'`"
sleep 60;
done



## if vm is running wait for shutdown (wait until)
#elif [ "$vmstatus" = "shut" ];
#vmstatus="`virsh --connect qemu+ssh://root@192.168.13.172/system remove $vmname`"

virsh -c qemu+ssh://root@192.168.13.172/system dumpxml $vmname > /tmp/tempxml

sed -i "/dev='network'/d" /tmp/tempxml					#remove the PXE boot option from the vm's xml 

#sed  -i "/dev='hd'/i \ <boot dev='network' />" /tmp/tempxml		#insert PXE boot 

virsh -c qemu+ssh://root@192.168.13.172/system define /tmp/tempxml	#redefine the VM based on the adjusted XML
virsh -c qemu+ssh://root@192.168.13.172/system start "$vmname"		#start the vm without pxe

else echo "vm is not shutdown"
fi
