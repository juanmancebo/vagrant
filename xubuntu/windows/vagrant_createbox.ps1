$VM="xubuntu"
$ISOFILE="xubuntu-20.04-desktop-amd64.iso"
$PROGRAMFILES_PATH = Get-ChildItem Env:PROGRAMFILES | select -expand Value
$VBOXMANAGE="$PROGRAMFILES_PATH\Oracle\VirtualBox\VBoxManage.exe"

$URI = "http://ftp.free.fr/mirrors/ftp.xubuntu.com/releases/20.04/release/$ISOFILE"
$OUTPUT = "$PSScriptRoot\$ISOFILE"
$START_TIME = Get-Date

if(Test-Path -path $OUTPUT)
{
	write-host("$OUTPUT already exists")
} else {
    write-host("Downloading $URI to $OUTPUT")
    (New-Object System.Net.WebClient).DownloadFile($URI, $OUTPUT)
    Write-Output "Time taken: $((Get-Date).Subtract($START_TIME).Seconds) second(s)"
} 



if (& $VBOXMANAGE list vms|findstr  \<$VM\>)
{
	
	write-host("VM $VM already exists. Exiting...")
	exit 1
}

Write-Output "VM $VM setup started"
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

Start-Sleep -s 400
$WAIT_SECONDS = 15
$EXIT_STATUS = "False"
$a=0
$number = 120
while (($EXIT_STATUS -eq "False") -and ($a -le $number))
{

 "Starting Loop $a"
 & $VBOXMANAGE guestcontrol $VM --verbose --username root --password vagrant run --exe "/bin/bash" -- arg0 "-c" -- "/bin/grep -q 'Final exit code:' /var/log/vboxpostinstall.log  &&  /bin/echo 'OK.Unattended install finished'|| /bin/echo 'Unattended install not finished yet. Retrying in $WAIT_SECONDS seconds'"
 $EXIT_STATUS = !$?
 Start-Sleep -s $WAIT_SECONDS
 $a++
 "Now a is $a and number is $number"

}

& $VBOXMANAGE guestcontrol $VM --username root --password vagrant copyto --target-directory /tmp/vagrant_tmp.sh ../../vagrant.sh
#& $VBOXMANAGE guestcontrol $VM --username root --password vagrant run --exe '/usr/bin/wget' -- arg0 -P /tmp "https://raw.githubusercontent.com/juanmancebo/vagrant/master/vagrant.sh"
& $VBOXMANAGE guestcontrol $VM --username root --password vagrant run --exe "/bin/bash" -- arg0 "-c" -- "tr -d '\r' < /tmp/vagrant_tmp.sh > /tmp/vagrant.sh"
& $VBOXMANAGE guestcontrol $VM --username root --password vagrant run --exe '/bin/bash' -- arg0 '-c' -- 'chmod +x /tmp/vagrant.sh && /tmp/vagrant.sh'
Write-Output "Powering off VM $VM"
& $VBOXMANAGE controlvm $VM acpipowerbutton
$WAIT_SECONDS = 3
$EXIT_STATUS = "False"
$a=0
$number = 10
while (($EXIT_STATUS -eq "False") -and ($a -le $number))
{

 "Starting Loop $a"
 & $VBOXMANAGE showvminfo $VM --machinereadable |findstr 'VMState=\"poweroff\"'
 $EXIT_STATUS = !$?
 Start-Sleep -s $WAIT_SECONDS
 $a++

}
Write-Output "VM $VM powered off"
& $VBOXMANAGE storageattach $VM --storagectl "IDE" --port 1 --device 0 --type dvddrive --medium "none"
Write-Output "VM $VM setup finished"
rm "$VM.box" -ea ig
Write-Output "Vagrant box $VM.box package started"
vagrant package --base $VM --output "$VM.box" $VM
Write-Output "Vagrant box $VM.box package finished"
vagrant box add "$VM.box" --name $VM --force
Write-Output "Cleaning up environment"
& $VBOXMANAGE unregistervm $VM --delete
rm "$HOME\VirtualBox VMs\$VM" -r -ea ig
Write-Output "Script finished"
Write-Output "Time taken: $((Get-Date).Subtract($START_TIME).Seconds) second(s)"
