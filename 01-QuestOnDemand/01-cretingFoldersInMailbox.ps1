<#
    This script authenticates to Microsoft Graph using the client credentials flow
    and creates a set of mail folders inside a specified user's mailbox.

    It performs the following actions:
      - Obtains an access token using tenant ID, client ID, and client secret.
      - Creates 5 root mail folders in the target mailbox.
      - Under each root folder, creates 2 subfolders.
      - Tracks successful root folder creations, successful subfolder creations,
        and any errors that occur.
      - Outputs a summary showing counts of created folders and any errors.
#>

####################
## Authentication ##
####################

$tenantId = ""
$clientId = ""
$clientSecret = ""

$body = @{
    client_id     = $clientId
    scope         = "https://graph.microsoft.com/.default"
    client_secret = $clientSecret
    grant_type    = "client_credentials"
}

$token = Invoke-RestMethod -Method Post `
    -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" `
    -Body $body

$accessToken = $token.access_token

######################
### Create Folders ###
######################

$userId = "teo@m365.dnsabr.com"

# Counters
$rootCount = 0
$subCount = 0
$errors = 0

# Quiet mode
Write-Host "Creating folders" -ForegroundColor Green

for ($i = 1; $i -le 5; $i++) {
    $rootName = "Test1SofiaUniFolder_$i"
    $rootBody = @{ displayName = $rootName } | ConvertTo-Json

    try {
        $root = Invoke-RestMethod -Method POST `
            -Uri "https://graph.microsoft.com/v1.0/users/$userId/mailFolders" `
            -Headers @{Authorization = "Bearer $accessToken"; "Content-Type" = "application/json" } `
            -Body $rootBody -ErrorAction Stop

        if ($null -ne $root.id) {
            $rootCount++
        }
        else {
            $errors++
        }
    }
    catch {
        $errors++
    }

    for ($j = 1; $j -le 2; $j++) {
        $childName = "SubSofiaUniFolder_${i}_$j"
        $childBody = @{ displayName = $childName } | ConvertTo-Json

        try {
            Start-Sleep -Milliseconds 300
            $child = Invoke-RestMethod -Method POST `
                -Uri "https://graph.microsoft.com/v1.0/users/$userId/mailFolders/$($root.id)/childFolders" `
                -Headers @{Authorization = "Bearer $accessToken"; "Content-Type" = "application/json" } `
                -Body $childBody -ErrorAction Stop

            if ($null -ne $child.id) {
                $subCount++
            }
            else {
                $errors++
            }
        }
        catch {
            $errors++
        }
    }
}

#############################
### Summary Output (Color) ###
#############################

Write-Host ""
Write-Host ("Created ") -ForegroundColor Green -NoNewline
Write-Host ("$rootCount") -ForegroundColor Red -NoNewline
Write-Host (" root folders and ") -ForegroundColor Green -NoNewline
Write-Host ("$subCount") -ForegroundColor Red -NoNewline
Write-Host (" subfolders.") -ForegroundColor Green

if ($errors -gt 0) {
    Write-Host ("There were $errors errors during execution.") -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Folder creation process completed." -ForegroundColor Green
