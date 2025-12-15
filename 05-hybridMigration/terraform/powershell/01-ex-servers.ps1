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

