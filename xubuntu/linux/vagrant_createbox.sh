#!/bin/bash

VM="xubuntu"

ISOFILE_32="xubuntu-18.04-desktop-i386.iso"
ISOFILE_64="xubuntu-20.04-desktop-amd64.iso"
ISOMD5_32="f74f01a3b7eeb99e8e28d8b9e2881cfc"
ISOMD5_64="c8977ce50d175dfce8e309dcaef8f1b3"
if egrep -qw "vmx|svm" /proc/cpuinfo
	then 
		echo "virtualization extension supported"
		hwvirtex=on
		ISOFILE=${ISOFILE_64}
		ISOMD5=${ISOMD5_64}
		RELEASE=20.04
		OSTYPE=Ubuntu_64
	else 
		echo "no virtualization extension supported"
		hwvirtex=off
		pae=on
		ISOFILE=${ISOFILE_32}
		ISOMD5=${ISOMD5_32}
		RELEASE=18.04
		OSTYPE=Ubuntu
fi

if [ -f ${ISOFILE} ]
then
	echo "iso file already exists"
	if [ $(md5sum ${ISOFILE}|awk '{print $1}') == ${ISOMD5} ]
	then 
		echo "md5 iso file ok"
	else
		echo "md5 iso file does not match. Downloading new one..."
		rm -f ${ISOFILE}
		wget http://ftp.free.fr/mirrors/ftp.xubuntu.com/releases/${RELEASE}/release/$ISOFILE
	fi
else
	echo "Downloading iso file..."
	wget http://ftp.free.fr/mirrors/ftp.xubuntu.com/releases/${RELEASE}/release/$ISOFILE
fi

if vboxmanage list vms|grep -qw $VM
then
	echo "vm $VM already exists. Exiting..."
	exit 1
fi




vboxmanage createvm --name $VM --ostype ${OSTYPE} --register
vboxmanage storagectl $VM --name "IDE" --add ide
vboxmanage storageattach $VM --storagectl "IDE" --port 1 --device 0 --type dvddrive --medium ${ISOFILE}
vboxmanage createhd --filename ${VM}.vdi --size 20000
vboxmanage storagectl $VM --name "SATA" --add sata --controller IntelAHCI --portcount 1
vboxmanage storageattach $VM --storagectl "SATA" --port 0 --device 0 --type hdd --medium ${VM}.vdi
vboxmanage modifyvm $VM --memory 1024 --vram 16
vboxmanage modifyvm $VM --accelerate3d off
vboxmanage modifyvm $VM --boot1 floppy --boot2 dvd --boot3 disk --boot4 none
vboxmanage modifyvm $VM --pae off
vboxmanage modifyvm $VM --graphicscontroller vmsvga
vboxmanage modifyvm $VM --audioout on --audioin off
vboxmanage modifyvm $VM --clipboard bidirectional --draganddrop bidirectional
vboxmanage modifyvm $VM --hwvirtex ${hwvirtex} --pae ${pae}

vboxmanage unattended install $VM --iso=${ISOFILE} --user=vagrant --full-user-name="vagrant" --password vagrant --hostname=vagrant.local --install-additions --locale=en_US --country=US --language=en-US --time-zone=UTC --script-template=/usr/lib/virtualbox/UnattendedTemplates/ubuntu_preseed.cfg --post-install-template=/usr/lib/virtualbox/UnattendedTemplates/debian_postinstall.sh

vboxmanage startvm $VM --type headless

################
sleep 400
WAIT_SECONDS=15
EXIT_STATUS=1
a=0
number=120

while [ $EXIT_STATUS -eq 1 ] && [ $a -le $number ]
do
 echo "Starting Loop $a"
 vboxmanage guestcontrol $VM --verbose --username root --password vagrant run --exe '/bin/bash' -- arg0 '-c' -- '/bin/grep -q "Final exit code:" /var/log/vboxpostinstall.log  &&  /bin/echo "OK.Unattended install finished"|| /bin/echo "Unattended install not finished yet. Retrying in ${WAIT_SECONDS} seconds"'
 EXIT_STATUS=$?
 sleep ${WAIT_SECONDS}
 a=$[$a+1]
 echo "Now a is $a and number is $number"
done

##################
echo "Executing post install scripts."
vboxmanage guestcontrol $VM --username root --password vagrant copyto --target-directory /tmp/vagrant_tmp.sh ../../vagrant.sh
#& $VBOXMANAGE guestcontrol $VM --username root --password vagrant run --exe '/usr/bin/wget' -- arg0 -P /tmp "https://raw.githubusercontent.com/juanmancebo/vagrant/master/vagrant.sh"
vboxmanage guestcontrol $VM --username root --password vagrant run --exe "/bin/bash" -- arg0 "-c" -- "tr -d '\r' < /tmp/vagrant_tmp.sh > /tmp/vagrant.sh"
vboxmanage guestcontrol $VM --username root --password vagrant run --exe '/bin/bash' -- arg0 '-c' -- 'chmod +x /tmp/vagrant.sh && md5sum /tmp/vagrant.sh && /tmp/vagrant.sh'
VBoxManage controlvm $VM acpipowerbutton
VBoxManage storageattach $VM --storagectl "IDE" --port 1 --device 0 --type dvddrive --medium "none"

if [ -f ${VM}.box ];then echo "Box file ${VM}.box already exists. Removing..." && rm -f ${VM}.box;fi
vagrant package --base $VM --output ${VM}.box $VM
vagrant box add ${VM}.box --name $VM --force
vboxmanage unregistervm ${VM} --delete
rm -rf  ~/VirtualBox\ VMs/${VM}
