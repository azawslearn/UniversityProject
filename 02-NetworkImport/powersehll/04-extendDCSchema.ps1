##########################################################
### EXTENDS AD SCHEMA BEFORE INSTALLATION OF EXCHNANGE ###
##########################################################


$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$localIso = 'C:\Users\azureuser\Desktop\EX-PREREQUISITES\Exchange2019-CU15.iso'
$orgName = 'First Organization'
$license = '/IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF'

Write-Host "=== $(Get-Date) Starting schema prep ==="
Write-Host "Using ISO: $localIso"

if (-not (Test-Path $localIso)) { throw "ISO file not found at $localIso" }

Write-Host "Mounting ISO..."
$disk = Mount-DiskImage -ImagePath $localIso -PassThru -ErrorAction Stop
$dvd = ($disk | Get-Volume).DriveLetter + ':'

foreach ($phase in 'PrepareSchema', 'PrepareAD', 'PrepareAllDomains') {
    $arguments = "/$phase $license"
    if ($phase -eq 'PrepareAD') { $arguments += " /OrganizationName:`"$orgName`"" }
    Write-Host "Running: $dvd\Setup.exe $arguments"
    Start-Process "$dvd\Setup.exe" -ArgumentList $arguments -Wait -PassThru
}

Dismount-DiskImage -ImagePath $localIso -ErrorAction Ignore
