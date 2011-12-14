#!/bin/bash


virsh -c qemu+ssh://root@192.168.13.172/system dumpxml SCORPIA01 > /tmp/tempxml
 
sed  -i "/dev='network'/d" /tmp/tempxml

virsh -c qemu+ssh://root@192.168.13.172/system define /tmp/tempxml
virsh -c qemu+ssh://root@192.168.13.172/system start SCORPIA01
