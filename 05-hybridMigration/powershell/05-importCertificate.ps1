###################
### Import Cert ###
###################

# Correct path
$CertPath = "$env:USERPROFILE\Desktop\EX2019Prerequsites\wildcardCompatibleM365.pfx"

# Password
$CertPassword = ConvertTo-SecureString -String "1" -AsPlainText -Force

# Import into Exchange
$importedCert = Import-ExchangeCertificate `
    -FileData ([Byte[]]$(Get-Content -Path $CertPath -Encoding Byte -ReadCount 0)) `
    -Password $CertPassword

# Enable for IIS + SMTP
Enable-ExchangeCertificate -Thumbprint $importedCert.Thumbprint -Services "IIS,SMTP"

# Verify
Get-ExchangeCertificate | fl Thumbprint, Services, Subject, NotAfter