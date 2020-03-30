## Give permissions to execute script in current user
https://docs.microsoft.com/es-es/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7

```
Set-ExecutionPolicy Unrestricted -Scope CurrentUser
Unblock-File -Path vagrant_createbox.ps1
```

## Execute script
```
.\vagrant_createbox.ps1
```