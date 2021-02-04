$Username      = $args[0]
$EmailPassword = $args[1]
$Subject       = $args[2]

$Log = Get-ChildItem -Path C:\Users\Ryan\Desktop\xmrig-6.7.0\backend\logs | Sort-Object LastAccessTime -Descending | Select-Object -First 1
$Username = $Username
$EmailTo = "xxx@xxx.com" 
$EmailFrom = "noreply@Whatever.notify"
$Subject = $Subject
$Body = Get-Content -Path C:\Users\Ryan\Desktop\xmrig-6.7.0\backend\logs\$Log | Out-String
$SMTPServer = "smtp.gmail.com" 
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587) 
$SMTPClient.EnableSsl = $true 
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($Username, $EmailPassword); 
$SMTPClient.Send($SMTPMessage)