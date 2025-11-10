##################################################################
### CONFIGURE BASIC EXCHANGE FUNCTIONALLITY AFTER INSTALLATION ###
##################################################################

# Configure Exchange virtual directories
$Server_name = "ex2016"
$FQDN = "mail.sofiauniversity.dnsabr.com"
$auto = "sofiauniversity.dnsabr.com"

Write-Host "Configuring Exchange virtual directories..."

# OWA
Get-OWAVirtualDirectory -Server $Server_name | Set-OWAVirtualDirectory -InternalURL "https://$FQDN/owa" -ExternalURL "https://$FQDN/owa"

# ECP
Get-ECPVirtualDirectory -Server $Server_name | Set-ECPVirtualDirectory -InternalURL "https://$FQDN/ecp" -ExternalURL "https://$FQDN/ecp"

# Offline Address Book
Get-OABVirtualDirectory -Server $Server_name | Set-OABVirtualDirectory -InternalURL "https://$FQDN/oab" -ExternalURL "https://$FQDN/oab"

# ActiveSync
Get-ActiveSyncVirtualDirectory -Server $Server_name | Set-ActiveSyncVirtualDirectory -InternalURL "https://$FQDN/Microsoft-Server-ActiveSync" -ExternalURL "https://$FQDN/Microsoft-Server-ActiveSync"

# EWS
Get-WebServicesVirtualDirectory -Server $Server_name | Set-WebServicesVirtualDirectory -InternalURL "https://$FQDN/EWS/Exchange.asmx" -ExternalURL "https://$FQDN/EWS/Exchange.asmx"

# MAPI
Get-MapiVirtualDirectory -Server $Server_name | Set-MapiVirtualDirectory -InternalURL "https://$FQDN/mapi" -ExternalURL "https://$FQDN/mapi" -IISAuthenticationMethods Negotiate, Basic, Ntlm

# Autodiscover
Set-ClientAccessService -Identity $Server_name -AutoDiscoverServiceInternalUri "https://autodiscover.$auto/Autodiscover/Autodiscover.xml"

# Outlook Anywhere
Get-OutlookAnywhere -Server $Server_name | Set-OutlookAnywhere `
    -ExternalHostname $FQDN `
    -InternalHostname $FQDN `
    -ExternalClientsRequireSsl $true `
    -InternalClientsRequireSsl $true `
    -ExternalClientAuthenticationMethod Negotiate `
    -IISAuthenticationMethods Negotiate, Basic, NTLM `
    -InternalClientAuthenticationMethod NTLM

Write-Host "Configured Exchange virtual directories."

# Optional verification
$OWA = Get-OWAVirtualDirectory -Server $Server_name -AdPropertiesOnly | Select InternalURL, ExternalURL
$ECP = Get-ECPVirtualDirectory -Server $Server_name -AdPropertiesOnly | Select InternalURL, ExternalURL
$OAB = Get-OABVirtualDirectory -Server $Server_name -AdPropertiesOnly | Select InternalURL, ExternalURL
$EAS = Get-ActiveSyncVirtualDirectory -Server $Server_name -AdPropertiesOnly | Select InternalURL, ExternalURL
$MAPI = Get-MapiVirtualDirectory -Server $Server_name -AdPropertiesOnly | Select InternalURL, ExternalURL

$OWA, $ECP, $OAB, $EAS, $MAPI | Format-Table

Get-ClientAccessService | Format-List AutoDiscoverServiceInternalUri

# Configure Accepted Domain and Email Address Policy
Write-Host "Configuring accepted domain and email address policy..."

New-AcceptedDomain -Name "sofiauniversity.dnsabr.com" -DomainName "sofiauniversity.dnsabr.com" -DomainType Authoritative | Set-AcceptedDomain -MakeDefault $true

New-EmailAddressPolicy -Name "sofiauniversity.dnsabr.com_policy" `
    -IncludedRecipients "AllRecipients" `
    -Priority "1" `
    -EnabledEmailAddressTemplates "SMTP:%g.%s@sofiauniversity.dnsabr.com"

Update-EmailAddressPolicy -Identity "sofiauniversity.dnsabr.com_policy"

Write-Host "Exchange configuration completed."


#https://mail.sofiauniversity.dnsabr.com/ecp
#https://mail.sofiauniversity.dnsabr.com/owa


#Get the name and the place of the DB of a specific server
Get-MailboxDatabase -Server ex2016-2 | Format-Table Name, EdbFilePath, LogFolderPath

#Getting all dbs that the server is aware of
Get-MailboxDatabase | Format-Table Name, Server, EdbFilePath, LogFolderPath

#Create DB and logs
New-MailboxDatabase -Name "DB2" -Server "ex2016-2" -EdbFilePath "C:\ExchangeDB\DB2\DB2.edb" -LogFolderPath "C:\ExchangeDB\DB2\Logs"
