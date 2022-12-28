#LandryLabs script to monitor for requests.
#landrylabs.bot@sparkhound.com
#May need to be the script constantly running for monitoring.

<#----------TO DO:
-BUILD:
--'PASSRESET' task.
--'TERMINATE' task.

-FIX:
--

-IMPROVE:
--
----------#>

<#----------Change Log:
+ Changed message trace section to dump the results of a scan into '...MonitoringScan.txt', then compare it against the existing log file '...MonitoringLog.txt' of scan history.
    The differences (new entries) are then compared against dedicated keywords assigned to certain requests.
+ Completed the 'UNLOCK' task implementation. Can now email landrylabs.bot@sparkhound.com with '[UNLOCK]_<username> to trigger this task to start.
+ Added a task labeled 'INFO' that will email the requester with information regarding the project and available commands.
----------#>

$Exit = 0

#Mailing info below
$LandryLabsBotPassFile = get-content -path "C:\users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Pass3.txt"
$PasswordLandryLabs = ConvertTo-SecureString $LandryLabsBotPassFile -AsPlainText -Force
$From = "landrylabs.bot@sparkhound.com";
$To = "daniel.landry@sparkhound.com";
$Port = 587
$Subject = "Pending"
$SMTPserver = "smtp.office365.com"
$Cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $from, $PasswordLandryLabs
$Signature = "`n`nThank you,`nLandryLabs Bot`nTask Assistant`nSend '[INFO]' in subject line for more information."

    
    $DateMonth = get-date -UFormat "%m"
    $DateDay = get-date -UFormat "%d"
    $DateYear = get-date -UFormat "%Y"
    $DateTime = get-date -UFormat "%R"
    $DateZoneOffset = get-date -UFormat %Z
    $StartTime = "$DateMonth/$DateDay/$DateYear $DateTime"
    "Genrating Trace Start Time: "; $StartTime


    #Email Monitoring
    $adminUser = "dalandry.admin@sparkhound.com"
    $AdminPassFile = Get-content -Path "C:\Users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Pass1.txt"
    $AdminPass = ConvertTo-SecureString $AdminPassFile -AsPlainText -Force
    $AdminCred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $adminUser, $AdminPass
    Connect-ExchangeOnline -Credential $AdminCred

    $LLMonitoringScan = "C:\users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Logs\LandryLabsBotMailboxMonitoringScan.txt"
    $LLMonitoringLog = "C:\users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Logs\LandryLabsBotMailboxMonitoringLog.txt"
    $LLActivityLog = "C:\Users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Logs\LandryLabsBotActivityLog.txt"
    $RequestLLInfo = "*INFO*";
    $RequestUnlock = "*UNLOCK*";
    $RequestOnboard = "ONBOARD";
    $RequestTerminate = "*TERM*";
    $RequestPassReset = "*PASSRESET*";


while ($exit -eq 0)
{   
    
    
    "Starting Exchange Message Trace - "; Get-Date; Tee-Object -FilePath $LLActivityLog
    $Trace = (get-messagetrace -recipientaddress "landrylabs.bot@sparkhound.com").subject
    $Trace | out-file $LLMonitoringScan
    $TraceNewEntries = Compare-object -ReferenceObject (get-content -path $LLMonitoringLog) -DifferenceObject (get-content -path $LLMonitoringScan) -PassThru
    $TraceNewEntries
    foreach ($entry in $TraceNewEntries) 
        {$entry; 
            if ($entry -like $RequestLLInfo)
                    {
                        "Event '$entry'detected. Forwarding LandryLabs information.";
                        $LandryLabsInfoSubject = "'LandryLabs.Bot' task assistant project. Information and Commands."
                                               $LandryLabsInfoBody = "Automation script assistant project by Daniel Landry.`n"
                        $LandryLabsInfoBody = ($LandryLabsInfoBody + "Tasks available (as of 12/2022):`n")
                        $LandryLabsInfoBody = ($LandryLabsInfoBody + "'[UNLOCK]' Request an AD account unlock`n'[PASSRESET]' Request an AD account reset");
                        $LandryLabsInfoBody = ($LandryLabsInfoBody + "'[TERM]' Request an AD account termination`n`n")
                        $LandryLabsInfoBody = ($LandryLabsInfoBody + "To properly submit your request, please enter the command (and only the command) into the subject field in the following formats:`n")
                        $LandryLabsInfoBody = ($LandryLabsInfoBody + "[TASK]_<firstname.lastname> | Ex: '[UNLOCK]_landrylabs.bot', '[PASSRESET]_landrylabs.bot'`n")
                        Send-MailMessage -from $From -To $To -Subject $LandryLabsInfoSubject -Body "$LandryLabsInfoBody`n$signature" -SmtpServer $SMTPserver -Credential $Cred -Verbose -UseSsl -Port $Port
                    }

            elseif ($entry -like $RequestUnlock) 
                    {
                        "Event '$entry' detected. Processing..."; Tee-Object -FilePath $LLActivityLog
                        $RequestArray = $entry -split "_";
                            foreach ($item in $RequestArray)
                                {
                                    $RequestBody = "Processing request...`nVerifying username...`n"; Tee-Object -FilePath $LLActivityLog
                                    $usernameverify = (get-aduser -identity $item -properties *).samaccountname
                                        if ($item -eq $usernameverify)
                                            {
                                                $RequestSubject = "Unlock request for $item updated."
                                                $RequestBody = ($RequestBody + "Username verified...`n`n");
                                                $UnlockVerify = (get-aduser -identity $item -properties *).lockedout
                                                    if ($UnlockVerify -eq "true")
                                                        {
                                                            $RequestBody = ($RequestBody + "Confirmed $item's account is locked.`n")
                                                            Unlock-ADAccount -Identity $item
                                                            $RequestSubject = "Unlock request for $item complete.`n"
                                                            $RequestBody = ($RequestBody + "Account has been unlocked.`nPlease confirm restored access.`n")
                                                        }
                                                    else
                                                        {
                                                            $RequestBody = ($RequestBody + "Account was confirmed to be NOT locked out...`n")
                                                        }
                                            }
                                        else
                                            {
                                                $RequestSubject = "$item invalid. Please provide a valid username."
                                                $RequestBody = ($RequestBody + "Username invalid. Please provide a valid username.`n")

                                            }

                                if ($item -eq "[UNLOCK]")
                                    {
                                        " "
                                    }
                                else
                                    {
                                        Send-MailMessage -from $From -To $To -Subject $RequestSubject -Body "$RequestBody`n$signature" -SmtpServer $SMTPserver -Credential $Cred -Verbose -UseSsl -Port $Port    
                                    }
                                
                                }



                    }
            elseif ($entry -like $RequestTerminate)
                    {
                        "Event '$entry' detected. Processing..."
                        $RequestArray = $entry -split "_";
                            foreach ($item in $RequestArray)
                                {
                                    $RequestBody = "Processing request...`nVerifying username...`n"; Tee-Object -FilePath $LLActivityLog
                                    $usernameverify = (get-aduser -identity $item -properties *).samaccountname  
                    }
            else
                {
                    "No requests detected..."

                }
            if ($TraceNewEntries -ne "Null")
                {
                    "Adding scanned entries to Log..."
                }
            else
                {
                    "Scan empty..."
                }
        }
    $TraceNewEntries | out-file $LLMonitoringLog -Append
    set-content -Path $LLMonitoringScan -Value " "
    "Next scan in 60 seconds."
sleep 60        
}

<#
    "Starting Exchange Message Trace"
    #$Trace = (get-messagetrace).subject
    $Trace = (get-messagetrace -recipientaddress "landrylabs.bot@sparkhound.com").subject
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
                #Test monitoring
        elseif
            ($entry -like "Timesheet approved*")
                {"Event 'Timessheet approved' detected. Sending acknowledgement email..."
                    $Subject = "$entry received. Processing..."; 
                    $Body = "$entry received. Processing...";
                    Send-MailMessage -from $From -To $To -Subject $Subject -Body "$Body`n$signature" -SmtpServer $SMTPserver -Credential $Cred -Verbose -UseSsl -Port $Port
                }
        else {""}

        }
    $DateDay = get-date -UFormat "%d"
    $DateYear = get-date -UFormat "%Y"
    $DateTime = get-date -UFormat "%R"
    $DateZoneOffset = get-date -UFormat %Z
    $StartTime = "$DateMonth/$DateDay/$DateYear $DateTime"
    "New Trace Start Time: "; $StartTime
sleep 300
#>


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