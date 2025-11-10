
###################################################
### INITIAL CONFIGURATION FOR DOMAIN CONTROLLER ###
###################################################

### Removes Complexity Locally ### - for easier management password for local admin is set to 1

secedit /export /cfg c:\secpol.cfg
(gc C:\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg
secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY
rm -force c:\secpol.cfg -confirm:$false
gpupdate /force

$Password = ConvertTo-SecureString "1" -AsPlainText -Force
$UserAccount = Get-LocalUser -Name "azureuser"
$UserAccount | Set-LocalUser -Password $Password

### disable all security on the server ####

$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"

Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
Set-ItemProperty -Path $UserKey  -Name "IsInstalled" -Value 0

### Disable Firewall with PS ###

Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled False
Set-MpPreference -DisableRealtimeMonitoring $true

### install chrome ###

$LocalTempDir = $env:TEMP
$ChromeInstaller = "$LocalTempDir\ChromeInstaller.exe"

Write-Host "Downloading Chrome installer"
(New-Object System.Net.WebClient).DownloadFile(
    'https://dl.google.com/chrome/install/375.126/chrome_installer.exe',
    $ChromeInstaller
)

Write-Host "Running Chrome installer"
& $ChromeInstaller /silent /install

Do {
    Start-Sleep 2
} Until (-not (Get-Process ChromeInstaller -ErrorAction SilentlyContinue))

Remove-Item $ChromeInstaller -ErrorAction SilentlyContinue

Write-Host "Chrome installation completed"

### install AD DS and reboot once ###

Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Import-Module ADDSDeployment

$DomainFqdn = "uniproject.local"
$Dsrmpwd = "Sup3r53cur3p455"

Install-ADDSForest `
    -DomainName $DomainFqdn `
    -ForestMode WinThreshold `
    -DomainMode WinThreshold `
    -InstallDns:$true `
    -SafeModeAdministratorPassword (ConvertTo-SecureString $Dsrmpwd -AsPlainText -Force) `
    -NoRebootOnCompletion:$false `
    -Force