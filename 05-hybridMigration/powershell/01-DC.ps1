#############################
### adding a suffix in AD ###
#############################
Get-ADForest | Format-List UPNSuffixes

Get-ADForest | Set-ADForest -UPNSuffixes @{add = "m365.dnsabr.com" }

###########################
#### DNS CONFIGURATION ####
###########################

Add-DnsServerPrimaryZone -Name "m365.dnsabr.com" -ReplicationScope "Forest" -PassThru

Add-DnsServerResourceRecordCName `
    -Name "dc" `
    -HostNameAlias "uniproject-dc.uniproject.local" `
    -ZoneName "m365.dnsabr.com"

Add-DnsServerResourceRecordCName `
    -Name "mail" `
    -HostNameAlias "EX2019.uniproject.local" `
    -ZoneName "m365.dnsabr.com"