##################################################################
### Create single Entra ID (Azure AD) user and assign licenses ###
### User: CloudSofiaUniPST@sofiauni.dnsabr.com                 ###
###################################################################

# Connect to Microsoft Graph with necessary scopes
Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All", "Organization.Read.All"

# User details
$domain = "sofiauniversity.dnsabr.com"
$upn = "CloudSofiaUniPST@$domain"
$alias = "CloudSofiaUniPST"
$password = "EmersonFitipaldi2023!"
$usageLocation = "BG"

# SKUs (same as your previous script)
$skuIds = @(
    [guid]"7e74bd05-2c47-404e-829a-ba95c66fe8e5", 
    [guid]"3271cf8e-2be5-4a09-a549-70fd05baaa17", 
    [guid]"52cdf00e-8303-4223-a749-ff69a13e2dd0"  
)

# Clean up any soft-deleted user with same UPN
$deleted = Get-MgDirectoryDeletedItemAsUser -All
$item = $deleted | Where-Object { $_.UserPrincipalName -ieq $upn -or $_.Mail -ieq $upn }
if ($item) {
    foreach ($i in $item) {
        Remove-MgDirectoryDeletedItem -DirectoryObjectId $i.Id -Confirm:$false
        Write-Host "Removed soft-deleted account: $upn"
    }
}

# Check if user already exists
$exists = $false
try {
    $null = Get-MgUser -UserId $upn -ErrorAction Stop
    $exists = $true
}
catch {}

if (-not $exists) {
    Write-Host "Creating user: $upn ..."
    New-MgUser `
        -AccountEnabled:$true `
        -DisplayName $alias `
        -MailNickname $alias `
        -UserPrincipalName $upn `
        -UsageLocation $usageLocation `
        -PasswordProfile @{ Password = $password; ForceChangePasswordNextSignIn = $false } `
    | Out-Null
}
else {
    Write-Host "User $upn already exists — updating usage location if needed ..."
    Update-MgUser -UserId $upn -UsageLocation $usageLocation -ErrorAction SilentlyContinue
}

# Assign licenses
$addLicenses = @()
foreach ($sku in $skuIds) { $addLicenses += @{ SkuId = $sku } }

try {
    Set-MgUserLicense -UserId $upn -AddLicenses $addLicenses -RemoveLicenses @() -ErrorAction Stop
    Write-Host "Assigned all licenses to $upn"
}
catch {
    Write-Warning "Failed assigning all SKUs at once — retrying one by one ..."
    foreach ($sku in $skuIds) {
        try {
            Set-MgUserLicense -UserId $upn -AddLicenses @(@{ SkuId = $sku }) -RemoveLicenses @() -ErrorAction Stop
            Write-Host "Assigned SKU $sku to $upn"
        }
        catch { Write-Warning "Could not assign SKU $sku" }
    }
}

Disconnect-MgGraph
Write-Host "`nUser $upn created and licensed successfully.`n"
