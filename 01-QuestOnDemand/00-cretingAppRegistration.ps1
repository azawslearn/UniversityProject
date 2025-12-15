###############################################
#            Client Credentials Flow           #
###############################################

<#
    This script creates an application registration in Microsoft 365.
    The resulting app registration and service principal will later be
    used to generate dummy data within a mailbox as part of testing.
#>

# Sign in with a Global Administrator using the following delegated scopes:
Connect-MgGraph -Scopes "Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All", "Directory.ReadWrite.All"

# Ensure MSAL.PS is available for working with client secrets
Install-Module MSAL.PS -Force
Import-Module MSAL.PS

###############################################
#            Client Credentials Flow           #
###############################################

# Create the application registration
$app = New-MgApplication -DisplayName "MyMailApp"

# Create the service principal for use within the tenant
$sp = New-MgServicePrincipal -AppId $app.AppId

# Create a client secret valid for one year
$secret = Add-MgApplicationPassword -ApplicationId $app.Id -PasswordCredential @{
    displayName = "mySecret"
    endDateTime = (Get-Date).AddYears(1)
}

# Output the essential identifiers
Write-Host "=== Copy these values securely ==="
Write-Host "App (Client) Id  : $($app.AppId)"
Write-Host "Tenant Id        : $((Get-MgContext).TenantId)"
Write-Host "Client Secret    : $($secret.SecretText)"

###################################################
#      Assign All Required Application Roles       #
###################################################

Connect-MgGraph -Scopes "Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All", "Directory.ReadWrite.All"

# Replace with your own values
$appId = ""
$tenantId = ""

# Retrieve the service principal for the application
$sp = Get-MgServicePrincipal -Filter "appId eq '$appId'"

# Retrieve the Microsoft Graph service principal (well-known AppId)
$graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"

# Resolve the AppRole IDs for required application permissions
$mailSend       = ($graphSp.AppRoles | Where-Object { $_.Value -eq "Mail.Send" -and $_.AllowedMemberTypes -contains "Application" }).Id
$mailReadWrite  = ($graphSp.AppRoles | Where-Object { $_.Value -eq "Mail.ReadWrite" -and $_.AllowedMemberTypes -contains "Application" }).Id
$calReadWrite   = ($graphSp.AppRoles | Where-Object { $_.Value -eq "Calendars.ReadWrite" -and $_.AllowedMemberTypes -contains "Application" }).Id
$groupRWAll     = ($graphSp.AppRoles | Where-Object { $_.Value -eq "Group.ReadWrite.All" -and $_.AllowedMemberTypes -contains "Application" }).Id
$sitesFullCtrl  = ($graphSp.AppRoles | Where-Object { $_.Value -eq "Sites.FullControl.All" -and $_.AllowedMemberTypes -contains "Application" }).Id
$filesRWAll     = ($graphSp.AppRoles | Where-Object { $_.Value -eq "Files.ReadWrite.All" -and $_.AllowedMemberTypes -contains "Application" }).Id

# Assign the application roles (admin consent)
New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -PrincipalId $sp.Id -ResourceId $graphSp.Id -AppRoleId $mailSend
New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -PrincipalId $sp.Id -ResourceId $graphSp.Id -AppRoleId $mailReadWrite
New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -PrincipalId $sp.Id -ResourceId $graphSp.Id -AppRoleId $calReadWrite
New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -PrincipalId $sp.Id -ResourceId $graphSp.Id -AppRoleId $groupRWAll
New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -PrincipalId $sp.Id -ResourceId $graphSp.Id -AppRoleId $sitesFullCtrl
New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -PrincipalId $sp.Id -ResourceId $graphSp.Id -AppRoleId $filesRWAll

Write-Host "Permissions Mail.Send, Mail.ReadWrite, Calendar.ReadWrite, Group.ReadWrite.All, Sites.FullControl.All, and Files.ReadWrite.All (Application) assigned."
