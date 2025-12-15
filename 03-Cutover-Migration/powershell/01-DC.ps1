################
## AD ISNTALL ##
################

# ---------- install AD DS and reboot once -----------------------------
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Import-Module ADDSDeployment

$DomainFqdn = "uniproject.local"
$Dsrmpwd = "Sup3r53cur3p455"

Install-ADDSForest `
    -DomainName $DomainFqdn `
    -ForestMode WinThreshold `
    -DomainMode WinThreshold `
    -InstallDns:$true `
    -SafeModeAdministratorPassword (ConvertTo-SecureString $Dsrmpwd -AsPlainText -Force) `
    -NoRebootOnCompletion:$false `
    -Force

########################
### AFTER AD INSTALL ###
########################

#############################
### adding a suffix in AD ###
#############################
Get-ADForest | Format-List UPNSuffixes

Get-ADForest | Set-ADForest -UPNSuffixes @{add = "sofiauniversity.dnsabr.com" }

###########################
#### DNS CONFIGURATION ####
###########################

Add-DnsServerPrimaryZone -Name "sofiauniversity.dnsabr.com" -ReplicationScope "Forest" -PassThru

Add-DnsServerResourceRecordCName `
    -Name "dc" `
    -HostNameAlias "uniproject-dc.uniproject.local" `
    -ZoneName "sofiauniversity.dnsabr.com"

Add-DnsServerResourceRecordCName `
    -Name "mail" `
    -HostNameAlias "EX2013.uniproject.local" `
    -ZoneName "sofiauniversity.dnsabr.com"