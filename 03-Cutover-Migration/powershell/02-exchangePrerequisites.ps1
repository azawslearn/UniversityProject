######################################################################
### DOWNLOADS ALL EXCHNEG PREREQUISITES IN A FOLDER ON THE DESKTOP ###
######################################################################


# Force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Define destination folder on current user's Desktop
$Desktop = [Environment]::GetFolderPath("Desktop")
$DestFolder = Join-Path $Desktop "EX-PREREQUISITES"

# Create the folder if it doesn't exist
if (-not (Test-Path $DestFolder)) {
    New-Item -ItemType Directory -Path $DestFolder | Out-Null
}

# Define prerequisites
$prereq_files = @(
    @{ name = "VC++ 2012 x64"; url = "https://download.microsoft.com/download/1/6/b/16b06f60-3b20-4ff2-b699-5e9b7962f9ae/VSU_4/vcredist_x64.exe"; dest = "vcredist2012_x64.exe" },
    @{ name = "VC++ 2013 x64"; url = "https://download.microsoft.com/download/2/e/6/2e61cfa4-993b-4dd4-91da-3737cd5cd6e3/vcredist_x64.exe"; dest = "vcredist2013_x64.exe" },
    @{ name = ".NET Framework 4.8"; url = "https://download.microsoft.com/download/f/3/a/f3a6af84-da23-40a5-8d1c-49cc10c8e76f/NDP48-x86-x64-AllOS-ENU.exe"; dest = "ndp48-x86-x64-allos-enu.exe" },
    @{ name = "UCMA 4.0"; url = "https://download.microsoft.com/download/2/c/4/2c47a5c1-a1f3-4843-b9fe-84c0032c61ec/UcmaRuntimeSetup.exe"; dest = "UcmaRuntimeSetup.exe" },
    @{ name = "URL Rewrite 2.1"; url = "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi"; dest = "rewrite_amd64_en-US.msi" }
)

# Download each file via BITS
foreach ($file in $prereq_files) {
    $destPath = Join-Path $DestFolder $file.dest
    Write-Host "Downloading $($file.name)..."
    Start-BitsTransfer -Source $file.url -Destination $destPath -DisplayName $file.name -Description "Downloading Exchange prerequisite"
    Write-Host "$($file.name) downloaded to $destPath"
}

Write-Host "`nAll files have been downloaded to: $DestFolder"
