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