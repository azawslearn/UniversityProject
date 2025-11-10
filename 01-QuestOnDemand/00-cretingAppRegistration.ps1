#################################
#### Client Credentials Flow ####
#################################
<#
This script will crete the application registration in Microsoft365 that we will later use to create all the
dummy data in the mailbox
#>

# sign in with a Global Administrator with the following scopes:
Connect-MgGraph -Scopes "Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All", "Directory.ReadWrite.All"

# so that we can use secret
Install-Module MSAL.PS -Force
Import-Module MSAL.PS

##################################
#### Client Credentials Flow ####
#################################

# Create the app
$app = New-MgApplication -DisplayName "MyMailApp"

# Create the service principal (so the app can actually be used in the tenant)
$sp = New-MgServicePrincipal -AppId $app.AppId

# Create a client secret (valid for 1 year)
$secret = Add-MgApplicationPassword -ApplicationId $app.Id -PasswordCredential @{displayName = "mySecret"; endDateTime = (Get-Date).AddYears(1) }

# Output the important details
Write-Host "=== Copy these values securely ==="
Write-Host "App (Client) Id  : $($app.AppId)"
Write-Host "Tenant Id        : $((Get-MgContext).TenantId)"
Write-Host "Client Secret    : $($secret.SecretText)"

##########################################
### ASSIGN ALL PERMISSIONS FOR THE APP ###
##########################################

Connect-MgGraph -Scopes "Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All", "Directory.ReadWrite.All"

# Replace with your own values
$appId = ""
$tenantId = ""

# Get the app's service principal
$sp = Get-MgServicePrincipal -Filter "appId eq '$appId'"

# Get Microsoft Graph service principal (well-known AppId)
$graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"

# Find AppRole IDs
$mailSend = ($graphSp.AppRoles | Where-Object { $_.Value -eq "Mail.Send" -and $_.AllowedMemberTypes -contains "Application" }).Id
$mailReadWrite = ($graphSp.AppRoles | Where-Object { $_.Value -eq "Mail.ReadWrite" -and $_.AllowedMemberTypes -contains "Application" }).Id
$calReadWrite = ($graphSp.AppRoles | Where-Object { $_.Value -eq "Calendars.ReadWrite" -and $_.AllowedMemberTypes -contains "Application" }).Id
$groupRWAll = ($graphSp.AppRoles | Where-Object { $_.Value -eq "Group.ReadWrite.All" -and $_.AllowedMemberTypes -contains "Application" }).Id
$sitesFullCtrl = ($graphSp.AppRoles | Where-Object { $_.Value -eq "Sites.FullControl.All" -and $_.AllowedMemberTypes -contains "Application" }).Id
$filesRWAll = ($graphSp.AppRoles | Where-Object { $_.Value -eq "Files.ReadWrite.All" -and $_.AllowedMemberTypes -contains "Application" }).Id

# Assign those roles (admin consent)
New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -PrincipalId $sp.Id -ResourceId $graphSp.Id -AppRoleId $mailSend
New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -PrincipalId $sp.Id -ResourceId $graphSp.Id -AppRoleId $mailReadWrite
New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -PrincipalId $sp.Id -ResourceId $graphSp.Id -AppRoleId $calReadWrite
New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -PrincipalId $sp.Id -ResourceId $graphSp.Id -AppRoleId $groupRWAll
New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -PrincipalId $sp.Id -ResourceId $graphSp.Id -AppRoleId $sitesFullCtrl
New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -PrincipalId $sp.Id -ResourceId $graphSp.Id -AppRoleId $filesRWAll

Write-Host "Permissions Mail.Send, Mail.ReadWrite, Calendar.ReadWrite, Group.ReadWrite.All, and Sites.FullControl.All (Application) assigned."