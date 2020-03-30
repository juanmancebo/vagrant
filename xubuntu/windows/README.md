
## Give permissions to execute script in current user
https://docs.microsoft.com/es-es/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7

```
Set-ExecutionPolicy Unrestricted -Scope CurrentUser
Unblock-File -Path vagrant_createbox.ps1
```

## Create vagrant box
```
.\vagrant_createbox.ps1
```

## VM provision and run
```
cd ..
vagrant up
```

## SSH access
```
vagrant ssh
```

## GUI mode access
| Default user     | Default password |
| ---      | ---       |
| vagrant | vagrant       |
