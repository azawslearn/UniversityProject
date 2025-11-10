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

$tokenResponse = Invoke-RestMethod -Method Post `
    -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" `
    -Body $body

$accessToken = $tokenResponse.access_token
$userId = "teo@m365.dnsabr.com"

############################
## Get All Mail Folders   ##
############################

Write-Host "Fetching all mail folders for $userId ..."

# Retrieve all mail folders recursively
function Get-MailFoldersRecursively {
    param (
        [string]$UserId,
        [string]$AccessToken,
        [string]$ParentFolderId = ""
    )

    $baseUri = if ($ParentFolderId) {
        "https://graph.microsoft.com/v1.0/users/$UserId/mailFolders/$ParentFolderId/childFolders"
    }
    else {
        "https://graph.microsoft.com/v1.0/users/$UserId/mailFolders"
    }

    $folders = @()
    $response = Invoke-RestMethod -Method GET -Uri $baseUri `
        -Headers @{Authorization = "Bearer $AccessToken" }

    if ($response.value) {
        foreach ($f in $response.value) {
            $folders += $f
            $folders += Get-MailFoldersRecursively -UserId $UserId -AccessToken $AccessToken -ParentFolderId $f.id
        }
    }

    return $folders
}

$mailFolders = Get-MailFoldersRecursively -UserId $userId -AccessToken $accessToken
Write-Host "Found $($mailFolders.Count) folders."

#####################################
## Create 5 Test Emails per Folder ##
#####################################

foreach ($folder in $mailFolders) {
    Write-Host "Processing folder: $($folder.displayName)"

    for ($k = 1; $k -le 2; $k++) {
        $subject = "Test Mail - $($folder.displayName) - $k"
        $bodyContent = "This is test message #$k created in folder '$($folder.displayName)' on $(Get-Date)."

        $messageBody = @{
            subject      = $subject
            body         = @{
                contentType = "Text"
                content     = $bodyContent
            }
            toRecipients = @(
                @{
                    emailAddress = @{
                        address = $userId
                    }
                }
            )
        } | ConvertTo-Json -Depth 5

        Invoke-RestMethod -Method POST `
            -Uri "https://graph.microsoft.com/v1.0/users/$userId/mailFolders/$($folder.id)/messages" `
            -Headers @{Authorization = "Bearer $accessToken"; "Content-Type" = "application/json" } `
            -Body $messageBody | Out-Null

        Write-Host "  └ Created test mail $k in folder '$($folder.displayName)'"
    }
}

Write-Host "All test mails created successfully."
