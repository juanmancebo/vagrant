#cd /usr/share/virtualbox
#sudo ln -s /usr/lib/virtualbox/UnattendedTemplates/ UnattendedTemplates
#cd -
VM="xubuntu_1804"
ISOFILE="xubuntu-18.04.3-desktop-amd64.iso"
wget http://ftp.free.fr/mirrors/ftp.xubuntu.com/releases/18.04/release/$ISOFILE
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
sleep 600
EXIT_STATUS=1
a=0
number=120

while [ $EXIT_STATUS -eq 1 ] && [ $a -le $number ]
do
 echo "Starting Loop $a"
 vboxmanage guestcontrol $VM --verbose --username root --password vagrant run --exe '/usr/bin/whoami'
 EXIT_STATUS=$?
 sleep 15
 a=$[$a+1]
 echo "Now a is $a and number is $number"
done

##################

echo "Executing post install scripts."
vboxmanage guestcontrol $VM --username root --password vagrant run --exe '/usr/bin/wget' -- arg0 -P /tmp "https://raw.githubusercontent.com/juanmancebo/vagrant/master/vagrant.sh"
vboxmanage guestcontrol $VM --username root --password vagrant run --exe '/bin/bash' -- arg0 '/tmp/vagrant.sh'
vboxmanage guestcontrol $VM --username root --password vagrant run --exe '/bin/rm' -- arg0 '/tmp/vagrant.sh'

if [ -f ${VM}.box ];then echo "Box file ${VM}.box already exists. Removing..." && rm -f ${VM}.box;fi
vagrant package --base $VM --output ${VM}.box $VM
vboxmanage unregistervm ${VM} --delete
rm -rf  ~/VirtualBox\ VMs/${VM}
vagrant box add ${VM}.box --name $VM --force
