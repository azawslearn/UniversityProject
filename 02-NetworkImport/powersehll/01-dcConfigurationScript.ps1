
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

# Enable TLS 1.2 for .NET Framework 4.x

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Enable TLS 1.2 for .NET Framework 4.x

Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value 1
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value 1