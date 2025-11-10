##########################################
### Create OU and Mailbox-Enabled User ###
##########################################

# Import AD module (needed for New-ADOrganizationalUnit)
if (-not (Get-Module ActiveDirectory -ErrorAction SilentlyContinue)) {
    Import-Module ActiveDirectory
}

# Variables
$OUName = "SofiaUniversityOU"
$OUPath = "DC=uniproject,DC=local"
$MailboxDB = "DB1"
$UserName = "LocalSofiaUniPST"
$UPN = "LocalSofiaUniPST@sofiauniversity.bg"
$Password = ConvertTo-SecureString "1" -AsPlainText -Force
$Email = "LocalSofiaUniPST@sofiauniversity.bg"

# Ensure OU exists
if (-not (Get-ADOrganizationalUnit -LDAPFilter "(name=$OUName)" -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name $OUName -Path $OUPath
    Write-Host "OU '$OUName' created under $OUPath"
}
else {
    Write-Host "OU '$OUName' already exists under $OUPath"
}

# Create the mailbox-enabled user
New-Mailbox -Name $UserName `
    -UserPrincipalName $UPN `
    -OrganizationalUnit "uniproject.local/$OUName" `
    -Password $Password `
    -Database $MailboxDB `
    -FirstName "Local" `
    -LastName "SofiaUniPST" `
    -DisplayName "LocalSofiaUniPST" `
    -ResetPasswordOnNextLogon $false

# Disable email address policy so we can set a custom SMTP
Set-Mailbox $UserName -EmailAddressPolicyEnabled $false

# Explicitly set primary SMTP address
Set-Mailbox $UserName -PrimarySmtpAddress $Email

# Verify
Get-Mailbox "LocalSofiaUniPST" | Format-List Name, Database, OrganizationalUnit
