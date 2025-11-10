########################################
### Adjusting DC GPO and CRETING DNS ###
########################################


#No complexity - allows to set the password for newly created user to "1" for easier management
$id = (Get-ADDomain).DistinguishedName
Set-ADDefaultDomainPasswordPolicy `
    -Identity $id `
    -ComplexityEnabled $False `
    -MinPasswordLength 1 `
    -PasswordHistoryCount 0 `
    -MinPasswordAge 00.00:00:00 `
    -MaxPasswordAge 00.00:00:00

gpupdate /force

#adding a suffix in AD
Get-ADForest | Format-List UPNSuffixes

Get-ADForest | Set-ADForest -UPNSuffixes @{add = "sofiauniversity.dnsabr.com" }

#### Creating a new DNS ZONE

Add-DnsServerPrimaryZone -Name "sofiauniversity.dnsabr.com" -ReplicationScope "Forest" -PassThru

Add-DnsServerResourceRecordCName `
    -Name "dc" `
    -HostNameAlias "uniproject-dc.uniproject.local" `
    -ZoneName "sofiauniversity.dnsabr.com"

Add-DnsServerResourceRecordCName `
    -Name "mail" `
    -HostNameAlias "ex2016.uniproject.local" `
    -ZoneName "sofiauniversity.dnsabr.com"

#Create UPN
Set-ADUser -Identity "azureuser" -UserPrincipalName "azureuser@sofiauniversity.dnsabr.com"

# Enable TLS 1.2 for .NET Framework 4.x

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Enable TLS 1.2 for .NET Framework 4.x

Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value 1
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value 1