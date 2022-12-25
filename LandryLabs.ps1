#LandryLabs script to monitor for requests.
#landrylabs.bot@sparkhound.com
#May need to be the script constantly running for monitoring.


<#----------Change Log:
+ Now scans ExchangeOnline for emails sent to 'landrylabs.bot@sparkhound.com'.
+ Included monitoring of strings '[TEST]', '[ONBOARDING]', and '[TERMINATION]' in the subject line for testing purposes.
+ Added instructions to generates message trace timestamps for 'startdate' and 'enddate' parameters to narrow down the scope of time to fetch results.
+ Added output verbiage to each if statement to report when it detects a certain keyword before it pushes out an acknowledgement email.
----------#>

$Exit = 0

#Mailing info below
$PasswordLandryLabs = ConvertTo-SecureString -String "Spike4650@landlabs" -AsPlainText -Force
$From = "landrylabs.bot@sparkhound.com";
$To = "daniel.landry@sparkhound.com";
$Port = 587
$Subject = "Pending"
$SMTPserver = "smtp.office365.com"
$Cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $from, $PasswordLandryLabs
$Signature = "`n`nThank you,`nLandryLabs Bot`nTask Assistant"

    $DateMonth = get-date -UFormat "%m"
    $DateDay = get-date -UFormat "%d"
    $DateYear = get-date -UFormat "%Y"
    $DateTime = get-date -UFormat "%R"
    $DateZoneOffset = get-date -UFormat %Z
    $StartTime = "$DateMonth/$DateDay/$DateYear $DateTime"
    "Genrating Trace Start Time: "; $StartTime


    #Email Monitoring
    $adminUser = "dalandry.admin@sparkhound.com"
    $AdminPass = ConvertTo-SecureString -String "Spike@admin2" -AsPlainText -Force
    $AdminCred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $adminUser, $AdminPass
    Connect-ExchangeOnline -Credential $AdminCred
<#
while ($exit -eq 0)
{   
    $DateMonth = get-date -UFormat "%m"
    $DateDay = get-date -UFormat "%d"
    $DateYear = get-date -UFormat "%Y"
    $DateTime = get-date -UFormat "%R"
    $EndTime = "$DateMonth/$DateDay/$DateYear $DateTime"
    "Generating Trace End Time: "; $EndTime
    

    "Starting Exchange Message Trace"
    $Trace = (get-messagetrace -recipientaddress "landrylabs.bot@sparkhound.com" -EndDate $EndTime -StartDate $StartTime).subject
    $Trace
    foreach ($entry in $Trace) 
        {if 
            ($entry -like "[TEST]*") 
                {"Event '[TEST]' detected. Sending acknowledgement email..."
                    $Subject = "$entry received. Disregarding."; 
                    $Body = "$entry received. Disregarding.";
                    Send-MailMessage -from $From -To $To -Subject $Subject -Body "$Body`n$signature" -SmtpServer $SMTPserver -Credential $Cred -Verbose -UseSsl -Port $Port
                }
        elseif 
            ($entry -like "[ONBOARDING]*")
                {"Event '[ONBOARDING]' detected. Sending acknowledgement email..."
                    $Subject = "$entry received. Processing..."; 
                    $Body = "$entry received. Processing...";
                    Send-MailMessage -from $From -To $To -Subject $Subject -Body "$Body`n$signature" -SmtpServer $SMTPserver -Credential $Cred -Verbose -UseSsl -Port $Port
                }
        elseif
            ($entry -like "[TERMINATION]*")
                {"Event '[TERMINATION]' detected. Sending acknowledgement email..."
                    $Subject = "$entry received. Processing..."; 
                    $Body = "$entry received. Processing...";
                    Send-MailMessage -from $From -To $To -Subject $Subject -Body "$Body`n$signature" -SmtpServer $SMTPserver -Credential $Cred -Verbose -UseSsl -Port $Port
                }



        }
    $DateDay = get-date -UFormat "%d"
    $DateYear = get-date -UFormat "%Y"
    $DateTime = get-date -UFormat "%R"
    $DateZoneOffset = get-date -UFormat %Z
    $StartTime = "$DateMonth/$DateDay/$DateYear $DateTime"
    "New Trace Start Time: "; $StartTime
sleep 300
}
#>

while ($exit -eq 0)
{   
    
    "Starting Exchange Message Trace"
    $Trace = (get-messagetrace -recipientaddress "landrylabs.bot@sparkhound.com").subject
    $Trace
    foreach ($entry in $Trace) 
        {if 
            ($entry -like "[TEST]*") 
                {"Event '[TEST]' detected. Sending acknowledgement email..."
                    $Subject = "$entry received. Disregarding."; 
                    $Body = "$entry received. Disregarding.";
                    Send-MailMessage -from $From -To $To -Subject $Subject -Body "$Body`n$signature" -SmtpServer $SMTPserver -Credential $Cred -Verbose -UseSsl -Port $Port
                }
        elseif 
            ($entry -like "[ONBOARDING]*")
                {"Event '[ONBOARDING]' detected. Sending acknowledgement email..."
                    $Subject = "$entry received. Processing..."; 
                    $Body = "$entry received. Processing...";
                    Send-MailMessage -from $From -To $To -Subject $Subject -Body "$Body`n$signature" -SmtpServer $SMTPserver -Credential $Cred -Verbose -UseSsl -Port $Port
                }
        elseif
            ($entry -like "[TERMINATION]*")
                {"Event '[TERMINATION]' detected. Sending acknowledgement email..."
                    $Subject = "$entry received. Processing..."; 
                    $Body = "$entry received. Processing...";
                    Send-MailMessage -from $From -To $To -Subject $Subject -Body "$Body`n$signature" -SmtpServer $SMTPserver -Credential $Cred -Verbose -UseSsl -Port $Port
                }



        }
    $DateDay = get-date -UFormat "%d"
    $DateYear = get-date -UFormat "%Y"
    $DateTime = get-date -UFormat "%R"
    $DateZoneOffset = get-date -UFormat %Z
    $StartTime = "$DateMonth/$DateDay/$DateYear $DateTime"
    "New Trace Start Time: "; $StartTime
sleep 300
}