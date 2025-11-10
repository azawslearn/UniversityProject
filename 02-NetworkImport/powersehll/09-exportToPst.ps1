###########################################
### Exchange 2016 Mailbox Export Script ###
###########################################

$ErrorActionPreference = "Stop"

# --- CONFIGURATION ---
$MailboxUpn = "LocalSofiaUniPST@sofiauniversity.bg"
$ExportFolder = "C:\PSTExports"
$ShareName = "PSTExports"
$PstName = "LocalSofiaUniPST.pst"

$Server = $env:COMPUTERNAME
$Domain = $env:USERDOMAIN
$UNCPath = "\\$Server\$ShareName\$PstName"
$ServerAcct = "$Server$"

Write-Host "=== Starting mailbox export process on $Server ==="

# --- Load Exchange cmdlets if not present ---
if (-not (Get-Command New-MailboxExportRequest -ErrorAction SilentlyContinue)) {
    try { Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn -ErrorAction Stop } catch {}
    try { Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn.E2010 -ErrorAction Stop } catch {}
}

# --- 1. Clean up old export requests ---
Write-Host "Cleaning old export requests..."
Get-MailboxExportRequest -ErrorAction SilentlyContinue | Remove-MailboxExportRequest -Confirm:$false -ErrorAction SilentlyContinue

# --- 2. Reset export folder and share ---
Write-Host "Resetting folder and share..."
cmd /c "net share $ShareName /delete >NUL 2>&1"

if (Test-Path $ExportFolder) {
    try { Remove-Item $ExportFolder -Recurse -Force -ErrorAction Stop } catch { }
}
New-Item -ItemType Directory -Path $ExportFolder -Force | Out-Null

# --- 3. Apply NTFS permissions ---
Write-Host "Applying NTFS permissions..."
$accounts = @(
    "$Domain\Exchange Trusted Subsystem",
    "$ServerAcct",
    "NETWORK SERVICE",
    "SYSTEM",
    "Administrators"
)

foreach ($acct in $accounts) {
    $cmd = "icacls `"$ExportFolder`" /grant `"$acct`":(OI)(CI)F /T"
    cmd /c $cmd | Out-Null
}

# --- 4. Create network share with matching rights ---
Write-Host "Creating network share..."
$shareCmd = "net share $ShareName=`"$ExportFolder`" /grant:`"$Domain\Exchange Trusted Subsystem`",FULL /grant:`"$ServerAcct`",FULL /grant:`"NETWORK SERVICE`",FULL /grant:`"Administrators`",FULL"
cmd /c $shareCmd | Out-Null

# --- 5. Restart Mailbox Replication Service ---
Write-Host "Restarting Mailbox Replication Service..."
Restart-Service MSExchangeMailboxReplication -Force

# --- 6. Submit export job ---
Write-Host "Submitting export for mailbox: $MailboxUpn ..."
New-MailboxExportRequest -Mailbox $MailboxUpn -FilePath $UNCPath | Out-Null

Write-Host "`nExport request created successfully."
Write-Host "PST will be saved to: $ExportFolder\$PstName"
Write-Host "Monitor progress manually with:"
Write-Host "Get-MailboxExportRequest | Get-MailboxExportRequestStatistics | ft DisplayName,Status,PercentComplete,FilePath"

Write-Host "`nWhen Status = Completed, the PST will appear in $ExportFolder"
Write-Host "=== Script complete ==="
