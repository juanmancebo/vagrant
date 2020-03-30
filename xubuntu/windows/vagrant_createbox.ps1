$VM="xubuntu_18042"
$ISOFILE="xubuntu-18.04.3-desktop-amd64.iso"
$VBOXMANAGE="C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

$url = "http://ftp.free.fr/mirrors/ftp.xubuntu.com/releases/18.04/release/$ISOFILE"
$output = "$PSScriptRoot\$ISOFILE"
$start_time = Get-Date
(New-Object System.Net.WebClient).DownloadFile($url, $output)
Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"


& $VBOXMANAGE createvm --name $VM --ostype "Ubuntu_64" --register
& $VBOXMANAGE storagectl $VM --name "IDE" --add ide
& $VBOXMANAGE storageattach $VM --storagectl "IDE" --port 1 --device 0 --type dvddrive --medium $ISOFILE
& $VBOXMANAGE createhd --filename $HOME\'VirtualBox VMs'\$VM\$VM.vdi --size 20000
& $VBOXMANAGE storagectl $VM --name "SATA" --add sata --controller IntelAHCI --portcount 1
& $VBOXMANAGE storageattach $VM --storagectl "SATA" --port 0 --device 0 --type hdd --medium $HOME\'VirtualBox VMs'\$VM\$VM.vdi
& $VBOXMANAGE modifyvm $VM --memory 1024 --vram 16
& $VBOXMANAGE modifyvm $VM --accelerate3d off
& $VBOXMANAGE modifyvm $VM --boot1 floppy --boot2 dvd --boot3 disk --boot4 none
& $VBOXMANAGE modifyvm $VM --pae off
& $VBOXMANAGE modifyvm $VM --graphicscontroller vmsvga
& $VBOXMANAGE modifyvm $VM --audioout on --audioin off
& $VBOXMANAGE modifyvm $VM --clipboard bidirectional --draganddrop bidirectional

& $VBOXMANAGE unattended install $VM --iso=$ISOFILE --user=vagrant --full-user-name="vagrant" --password vagrant --hostname=vagrant.local --install-additions --locale=en_US --country=US --language=en-US --time-zone=UTC

& $VBOXMANAGE startvm $VM --type headless

Start-Sleep -s 600
$EXIT_STATUS = "False"
$a=0
$number = 120
while (($EXIT_STATUS -eq "False") -and ($a -le $number))
{

 "Starting Loop $a"
 & $VBOXMANAGE guestcontrol $VM --verbose --username root --password vagrant run --exe '/usr/bin/whoami'
 $EXIT_STATUS = !$?
 Start-Sleep -s 15
 $a++
 "Now a is $a and number is $number"

}


& $VBOXMANAGE guestcontrol $VM --verbose --username root --password vagrant run --exe '/usr/bin/wget' -- arg0 -P /tmp arg1 "https://raw.githubusercontent.com/juanmancebo/vagrant/master/xubuntu/vagrant.sh"
& $VBOXMANAGE guestcontrol $VM --verbose --username root --password vagrant run --exe '/bin/bash' -- arg0 '/tmp/vagrant.sh'
& $VBOXMANAGE guestcontrol $VM --verbose --username root --password vagrant run --exe '/bin/rm' -- arg0 '/tmp/vagrant.sh'

#rm "$VM.box" -ea ig
vagrant package --base $VM --output "$VM.box" $VM
#& $VBOXMANAGE unregistervm $VM --delete
#rm "$HOME\VirtualBox VMs\$VM" -r -ea ig
vagrant box add "$VM.box" --name $VM --force
