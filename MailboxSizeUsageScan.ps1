#==========^==========#
    # MAILBOX STORAGE MONITOR (SH AND IMS)
    #==========v==========#
    <#-User mailbox sizes (in % and GB); & User mailbox X% until full.
        1. Fetches all of the mailbox email addresses, 
        2. Divides the mailboxes used size by the total mailbox size to get a 'percentage used',
            -Converts the strings into ONLY the numerical bytes to allow calculations.
        3. Targets mailboxes with resulting values of '0.95' (95%) usage and outputs their used, deleted, total, and archive enabled/disabled information into a variable.
        4. Pushes a custom email alert with their email address contianing the contents of that mailbox information variable:
        Ex email: 
          ===================
          <email> 
          Used: 92.67 GB (99,505,953,735 bytes)
          Deleted: 48.28 MB (50,624,861 bytes)
          Total: 100 GB (107,374,182,400 bytes)
          Archive Mailbox not enabled.
          ===================
    -Initial build that works as intended. WIll clean up as needed later.
    -Need to see how effectively I can have this in a script that will swap between each IMS Exchange Online shells to run this and push emails out. 
    #>
    Connect-ExchangeOnline
    $Mailbox = (get-mailbox | sort -property primarysmtpaddress).primarysmtpaddress
    foreach ($user in $Mailbox)
        {
            #Fetching mailbox used size and rebuilding the bytes value to be used in calculations#
            $MailboxUsedSize = (get-mailboxstatistics -Identity $user).totalitemsize.value;
            $NewUsedSize = "$MailboxUsedSize"
            $NewUsedSizeSplit = $NewUsedSize.Split(" "); #Splitting into an array to focus into the byte size easier.
            $UsedSizeStageTwo = $NewUsedSizeSplit[2].Substring(1); #New string removing the '(' character.
            $UsedSizeStageTwoSplit = $UsedSizeStageTwo.Split(","); #Splitting using comma delimmiter to kill the commas.
            $MBUsedSizeFinal = $UsedSizeStageTwoSplit[0]+$UsedSizeStageTwoSplit[1]+$UsedSizeStageTwoSplit[2]+$UsedSizeStageTwoSplit[3]; #Re-joining the array into a string capable of calculations.

            #Fetching mailbox total size and rebuilding the bytes value to be used in calculations#
            $MailboxTotalSize = (get-mailbox -Identity $user).ProhibitSendReceiveQuota;
            $NewTotalSize = "$MailboxTotalSize"
            $NewTotalSizeSplit = $NewTotalSize.Split(" "); #Splitting into an array to focus into the byte size easier.
            $TotalSizeStageTwo = $NewTotalSizeSplit[2].Substring(1); #New string removing the '(' character.
            $TotalSizeStageTwoSplit = $TotalSizeStageTwo.Split(","); #Splitting using comma delimmiter to kill the commas.
            $MBTotalSizeFinal = $TotalSizeStageTwoSplit[0]+$TotalSizeStageTwoSplit[1]+$TotalSizeStageTwoSplit[2]+$TotalSizeStageTwoSplit[3]; #Re-joining the array into a string capable of calculations.
            
            #Fetching mailbox deleted size#
            $MailboxDeletedSize = (get-mailboxstatistics -Identity $user).totaldeleteditemsize.Value;

            #Information below used to send email alert#
            $EmailPass = "*REMOVED*"
            $PasswordEmail = ConvertTo-SecureString $EmailPass -AsPlainText -Force
            $From = "landrylabs.bot@sparkhound.com";
            $To = "daniel.landry@sparkhound.com";
            $Port = 587
            $Subject = "Exchange Monitoring Alert [Mailbox Is Over 95% Full]"
            $SMTPserver = "smtp.office365.com"
            $Cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $from, $PasswordEmail
            $Signature = "`n`nThank you,`nLandryLabs`nMonitoring Assistant."
            

            if ($MBUsedSizeFinal/$MBTotalSizeFinal -le .5)
                {
                    Write-Host "#" -NoNewline 
                }
            elseif ($MBUsedSizeFinal/$MBTotalSizeFinal -ge .95)
                {   
                    Write-Host "!" -NoNewline;
                    $Subject = "Exchange Monitoring Alert [Mailbox Is Over 95% Full]"
                    $EmailBody = "===================`n"
                    $EmailBody = ($EmailBody +"$user `n"); 
                    $EmailBody = ($EmailBody +"Used: "+$MailboxUsedSize+"`n");
                    $EmailBody = ($EmailBody +"Deleted: "+$MailboxDeletedSize+"`n");
                    $EmailBody = ($EmailBody +"Total: "+$MailboxTotalSize+"`n");
                        if ((get-mailbox -Identity $user).ArchiveStatus -eq 'None') #'None' value mostly confirms that an archiving mailbox does't exist. Skips attempting to fetch that info if so.
                            {
                                $EmailBody = ($EmailBody +"Archive Mailbox not enabled.`n");
                            }
                        elseif ((get-mailbox -identity $user).ArchiveStatus -eq 'Active') #'Active' mostly confirms an archive mailbox exists and is active. Fetches archive mailbox info.
                            {
                                $EmailBody = ($EmailBody +"Archive: "+(get-mailbox -Identity $user).ArchiveStatus);
                                $EmailBody = ($EmailBody +"Archive Used: "+(get-mailboxstatistics $user -Archive).totalitemsize.Value);
                                $EmailBody = ($EmailBody +"Archive Deleted: "+(get-mailboxstatistics $user -Archive).totaldeleteditemsize.Value);
                            }
                    $EmailBody = ($EmailBody +"===================`n")
                    Send-MailMessage -from $From -To $To -Subject $Subject -Body "$EmailBody`n$signature" -SmtpServer $SMTPserver -Credential $Cred -Verbose -UseSsl -Port $Port
                }  
        }