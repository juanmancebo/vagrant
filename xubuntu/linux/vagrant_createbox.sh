#!/bin/bash

VM="xubuntu_1804"
ISOFILE="xubuntu-18.04.3-desktop-amd64.iso"
ISOMD5="0c268a465d5f48a30e5b12676e9f1b36"
if [ -f ${ISOFILE} ]
then
	echo "iso file already exists"
	if [ $(md5sum ${ISOFILE}|awk '{print $1}') == ${ISOMD5} ]
	then 
		echo "md5 iso file ok"
	else
		echo "md5 iso file does not match. Downloading new one..."
		rm -f ${ISOFILE}
		wget http://ftp.free.fr/mirrors/ftp.xubuntu.com/releases/18.04/release/$ISOFILE
	fi
else
	echo "Downloading iso file..."
	wget http://ftp.free.fr/mirrors/ftp.xubuntu.com/releases/18.04/release/$ISOFILE
fi
vboxmanage createvm --name $VM --ostype "Ubuntu_64" --register
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

vboxmanage unattended install $VM --iso=${ISOFILE} --user=vagrant --full-user-name="vagrant" --password vagrant --hostname=vagrant.local --install-additions --locale=en_US --country=US --language=en-US --time-zone=UTC --script-template=/usr/lib/virtualbox/UnattendedTemplates/ubuntu_preseed.cfg

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
vboxmanage guestcontrol $VM --username root --password vagrant copyto --target-directory /tmp ../../vagrant.sh 
#vboxmanage guestcontrol $VM --username root --password vagrant run --exe '/usr/bin/wget' -- arg0 -P /tmp "https://raw.githubusercontent.com/juanmancebo/vagrant/master/vagrant.sh"
echo $?
vboxmanage guestcontrol $VM --username root --password vagrant run --exe '/usr/bin/md5sum' -- arg0 '/tmp/vagrant.sh'
echo $?
vboxmanage guestcontrol $VM --username root --password vagrant run --exe '/bin/bash' -- arg0 '-c' -- 'chmod +x /tmp/vagrant.sh && /tmp/vagrant.sh'
echo $?

#if [ -f ${VM}.box ];then echo "Box file ${VM}.box already exists. Removing..." && rm -f ${VM}.box;fi
#vagrant package --base $VM --output ${VM}.box $VM
#vboxmanage unregistervm ${VM} --delete
#rm -rf  ~/VirtualBox\ VMs/${VM}
#vagrant box add ${VM}.box --name $VM --force
