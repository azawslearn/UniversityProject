###########################################
### disable all security on the server ####
###########################################

$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
Stop-Process -Name Explorer
Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green

################################
### Disable Firewall with PS ###
################################

Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled False
Set-MpPreference -DisableRealtimeMonitoring $true

######################
### install chrome ###
######################


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