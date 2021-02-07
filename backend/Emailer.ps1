$Username      = $args[0]
$EmailPassword = $args[1]
$Subject       = $args[2]
$LogFile       = $args[3]	
$EmailTo       = $args[4]
$SMTPServer    = $args[5]
$SMTPPort      = $args[6]

$Username = $Username
 
$EmailFrom = "noreply@Whatever.notify"
$Subject = $Subject
$Body = Get-Content -Path $LogFile | Out-String
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body)
$SMTPClient = New-Object Net.Mail.SmtpClient($SMTPServer, $SMTPPort) 
$SMTPClient.EnableSsl = $true 
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($Username, $EmailPassword); 
$SMTPClient.Send($SMTPMessage)