######################################################################
### INSTALLS ALL EXCHNEG PREREQUISITES IN A FOLDER ON THE DESKTOP ###
######################################################################


# Show hidden files, folders, and drives
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' `
    -Name Hidden -Value 1

# Show protected operating system files (set to 1 = show, 2 = hide)
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' `
    -Name ShowSuperHidden -Value 1

# Show file name extensions
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' `
    -Name HideFileExt -Value 0

#enabling CredSSP
Enable-WSManCredSSP -Role Server -Force

# Minimal Exchange 2016 prereqs installer
$InstallerPath = "$env:USERPROFILE\Desktop\EX-PREREQUISITES"

# 1) .NET 4.8 already?
try { $rel = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full').Release } catch { $rel = 0 }
if ($rel -ge 528040) {
    Write-Host ".NET Framework 4.8 already installed. Exiting."
    exit 0
}

#share the folder for extending schema
New-SmbShare -Name "EX-PREREQUISITES" -Path "C:\Users\azureuser\Desktop\EX-PREREQUISITES" -FullAccess "Everyone"


# 2) Windows features (idempotent)
Write-Host "Installing Windows Features..."
Install-WindowsFeature RSAT-ADDS | Out-Null
Install-WindowsFeature NET-Framework-45-Core, NET-Framework-45-ASPNET, NET-WCF-HTTP-Activation45, `
    NET-WCF-Pipe-Activation45, NET-WCF-TCP-Activation45, NET-WCF-TCP-PortSharing45, `
    Server-Media-Foundation, RPC-over-HTTP-proxy, RSAT-Clustering, RSAT-Clustering-CmdInterface, `
    RSAT-Clustering-Mgmt, RSAT-Clustering-PowerShell, WAS-Process-Model, Web-Asp-Net45, `
    Web-Basic-Auth, Web-Client-Auth, Web-Digest-Auth, Web-Dir-Browsing, Web-Dyn-Compression, `
    Web-Http-Errors, Web-Http-Logging, Web-Http-Redirect, Web-Http-Tracing, Web-ISAPI-Ext, `
    Web-ISAPI-Filter, Web-Lgcy-Mgmt-Console, Web-Metabase, Web-Mgmt-Console, Web-Mgmt-Service, `
    Web-Net-Ext45, Web-Request-Monitor, Web-Server, Web-Stat-Compression, Web-Static-Content, `
    Web-Windows-Auth, Web-WMI, Windows-Identity-Foundation, RSAT-ADDS | Out-Null

# 3) Paths that match your folder
$vc2012 = Join-Path $InstallerPath 'vcredist2012_x64.exe'
$vc2013 = Join-Path $InstallerPath 'vcredist2013_x64.exe'
$ucma = Join-Path $InstallerPath 'UcmaRuntimeSetup.exe'
$rewrite = Join-Path $InstallerPath 'rewrite_amd64_en-US.msi'
$net48 = Join-Path $InstallerPath 'ndp48-x86-x64-allos-enu.exe'

Write-Host "Installing VC++ 2012..."
Start-Process $vc2012 -ArgumentList '/quiet /norestart' -Wait

Write-Host "Installing VC++ 2013..."
Start-Process $vc2013 -ArgumentList '/quiet /norestart' -Wait

Write-Host "Installing UCMA 4.0..."
Start-Process $ucma -ArgumentList '/quiet /norestart' -Wait

Write-Host "Installing URL Rewrite 2.1..."
Start-Process msiexec.exe -ArgumentList "/i `"$rewrite`" /quiet /norestart" -Wait

Write-Host "Installing .NET Framework 4.8 (last)..."
Start-Process $net48 -ArgumentList '/q /norestart' -Wait

Write-Host "All installations done. Rebooting..."
Restart-Computer -Force