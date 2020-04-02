### Open Powershell
```
(Windows logo key  + R) and type powershell
```

### Give permissions to execute script
```
Set-ExecutionPolicy Unrestricted -Scope CurrentUser
Unblock-File -Path vagrant_createbox.ps1
```

### Create vagrant box
```
.\vagrant_createbox.ps1
```

### VM provision and run
```
cd ..
vagrant up
```

### SSH access
```
vagrant ssh
```

### GUI mode access
| Default user     | Default password |
| ---      | ---       |
| vagrant | vagrant       |
