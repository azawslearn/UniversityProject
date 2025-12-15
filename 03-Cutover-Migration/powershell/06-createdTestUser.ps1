Import-Module ActiveDirectory

# Variables
$OUName      = "CutoverMigration"
$OUPath      = "DC=uniproject,DC=local"
$OUFull      = "OU=CutoverMigration,DC=uniproject,DC=local"

$UserName      = "CutoverMigrationUser"
$SamAccount    = "CutoverMigrationUser"
$UPNSuffix     = "sofiauniversity.dnsabr.com"
$PasswordPlain = "1"

# -----------------------------
# 1. Ensure OU exists
# -----------------------------
$OUObject = Get-ADOrganizationalUnit -LDAPFilter "(distinguishedName=$OUFull)" -ErrorAction SilentlyContinue
if (-not $OUObject) {
    Write-Host "OU does not exist. Creating $OUFull ..."
    New-ADOrganizationalUnit -Name $OUName -Path $OUPath -ProtectedFromAccidentalDeletion $false
} else {
    Write-Host "OU already exists: $OUFull"
}

# -----------------------------
# 2. Ensure user exists
# -----------------------------
$UserObject = Get-ADUser -Filter "SamAccountName -eq '$SamAccount'" -ErrorAction SilentlyContinue

if (-not $UserObject) {
    Write-Host "User does not exist. Creating user $UserName ..."

    $Password = ConvertTo-SecureString $PasswordPlain -AsPlainText -Force

    New-ADUser `
        -Name $UserName `
        -SamAccountName $SamAccount `
        -UserPrincipalName "$UserName@$UPNSuffix" `
        -Path $OUFull `
        -Enabled $true `
        -AccountPassword $Password `
        -PasswordNeverExpires $true

    Write-Host "User created: $UserName"
} else {
    Write-Host "User already exists: $UserName"
}

# -----------------------------
# 3. Ensure mailbox exists
# -----------------------------
# Import Exchange module if needed
if (-not (Get-PSSnapin | Where-Object {$_.Name -eq "Microsoft.Exchange.Management.PowerShell.E2010"})) {
    Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction SilentlyContinue
}

try {
    $Mailbox = Get-Mailbox -Identity $SamAccount -ErrorAction Stop
    Write-Host "Mailbox already exists for $UserName"
}
catch {
    Write-Host "Mailbox does not exist. Creating mailbox for $UserName ..."
    Enable-Mailbox -Identity $SamAccount
    Write-Host "Mailbox created for $UserName"
}



