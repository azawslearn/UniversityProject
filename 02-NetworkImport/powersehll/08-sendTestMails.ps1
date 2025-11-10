###############################################
### Send 10 test mails to tes the migration ###
###############################################

$Mailbox = "LocalSofiaUniPST@sofiauniversity.bg"
$From = "Administrator@uniproject.local"  # any valid sender
$Smtp = "localhost"                       # Exchange Transport service on same box
$Count = 10

for ($i = 1; $i -le $Count; $i++) {
    $Subject = "Test Message From SOFIA UNIVERSITY $i"
    $Body = "From SOFIA UNIVERSITY number $i sent on $(Get-Date)."
    Send-MailMessage -To $Mailbox -From $From -Subject $Subject -Body $Body -SmtpServer $Smtp
    Write-Host "Sent test email #$i to $Mailbox"
}

Write-Host "Completed sending $Count test messages to $Mailbox."
