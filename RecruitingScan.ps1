#Intended as a proactive effort on maintaining visibility on the hiring pipeline of Sparkhound to better prepare ahead of time for new hires.


$host.ui.rawui.WindowTitle = "RECRUITING SCAN"
$Stop = "N"
do
    {
        $TraceResults = @()
        $TraceMessageTraceID = @(get-messagetrace -SenderAddress recruiting@sparkhound.com).messagetraceid
        $TraceReceived = @(get-messagetrace -SenderAddress recruiting@sparkhound.com).Received
        $TraceRecipientAddress = @(get-messagetrace -SenderAddress recruiting@sparkhound.com).RecipientAddress
        $TraceSubject = @(get-messagetrace -SenderAddress recruiting@sparkhound.com).Subject

        $i = 0;
        if ($TraceMessageTraceID -ne $Null)
            {
                foreach ($id in $TraceMessageTraceID)
                    {       
                        $TraceResults += "====================`n"
                        $TraceResults += "MessageTraceID: $id`n"
                        $TraceResults += "Recieved " + $TraceReceived[$i] + "`n"
                        $TraceResults += "Recipient Address: " + $TraceRecipientAddress[$i] + "`n"
                        $TraceResults += "Subject: " + $TraceSubject[$i] + "`n"
                        $TraceResults += "====================`n"
                        $i++
                    }

                #$TraceResults

                $EmailPass = "*REMOVED*"
                $PasswordEmail = ConvertTo-SecureString $EmailPass -AsPlainText -Force
                $from = "landrylabs.bot@sparkhound.com";
                $To = "daniel.landry@sparkhound.com";
                $Port = 587
                $Subject = "Recruitment Trace Results (last 48 hours)."
                $SMTPserver = "smtp.office365.com"
                $Cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $from, $PasswordEmail
                #$Signature = "`n`nThank you,`nLandryLabs `nAutomation Assistant `nOnboarding Questions? Email 'mi-t2@sparkhound.com'"


                Send-MailMessage -from $From -To $To -Subject $Subject -Body "$TraceResults" -SmtpServer $SMTPserver -Credential $Cred -Verbose -UseSsl -Port $Port
                Write-Host "$(Get-Date) - Activity Detected. Email Pushed."
            }
        else 
            {
                Write-Host "$(Get-Date) - No Activity Detected."
            }
        
    start-sleep 3600
    }
until ($Stop -eq "Y")










<# $Date = get-Date
$Day = $Date.Day
$Month = $date.Month
$Year = $date.Year
$Hour = $date.Hour
$Minute = $date.Minute
$Second = $date.Second

$OneHourAgo = $date.AddHours(-1)
$TraceEndDate = "$Month/$Day/$Year $Hour" + ":" + "$Minute" + ":" + "$Second"
$TraceStartDate = "$Month/$Day/$Year $Hour" + ":" + "$Minute" + ":" + "$Second"
#$OneHourAgo
#$TraceStartDate
#$TraceEndDate #>

#$MailArchivePath = "$pwd\MailCrawl"
#$MailArchiveFile = "$MailArchivePath\MessageIDArchive.txt"
#$Archive = Get-Content -Path $MailArchiveFile




<# $EmailContent = get-content -Path "C:\Users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Tasks\SPARKHOUND High Severity Security Center Alert.msg" -delimiter ','
$I = 1
$AlertidDetect = " A l e r t I d "
$Hello = "Hello,"
$AlertidDetectWildCard = "*$AlertidDetect*"
foreach ($String in $EmailContent)
    {
        if ($string -eq $AlertidDetect)
            {
                "AlertID"
                $string
            }

        elseif ($string -like $Hello)
            {
                "Hello"
                $String
            }
        else
            {
                $String
                "no"
            }
    } #>