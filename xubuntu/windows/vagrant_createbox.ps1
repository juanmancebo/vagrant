$VM="xubuntu_1804"
$ISOFILE="xubuntu-18.04.3-desktop-amd64.iso"
$PROGRAMFILES_PATH = Get-ChildItem Env:PROGRAMFILES | select -expand Value
$VBOXMANAGE="$PROGRAMFILES_PATH\Oracle\VirtualBox\VBoxManage.exe"

$url = "http://ftp.free.fr/mirrors/ftp.xubuntu.com/releases/18.04/release/$ISOFILE"
$output = "$PSScriptRoot\$ISOFILE"
$start_time = Get-Date

if(Test-Path -path $output)
{
	write-host("$output already exists")
} else {
	(New-Object System.Net. already existsWebClient).DownloadFile($url, $output)
    Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
} 



if (& $VBOXMANAGE list vms|findstr  \<$VM\>)
{
	
	write-host("vm $VM already exists. Exiting...")
	exit 1
}

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
& $VBOXMANAGE controlvm $VM acpipowerbutton

rm "$VM.box" -ea ig
vagrant package --base $VM --output "$VM.box" $VM
vagrant box add "$VM.box" --name $VM --force
& $VBOXMANAGE unregistervm $VM --delete
rm "$HOME\VirtualBox VMs\$VM" -r -ea ig