<#

#      || LANDRY LABS - UNTITLED MONITORING SCRIPT
#      || SUMMARY: FINAL T.B.D. 
# #    || 
####   ||  
  #    || 
  #### || Written by Daniel Landry (daniel.landry@sparkhound.com)

#>

<#----------Initial scoping draft for a monitoring project.
-Currently fetching the following from Active Directory:
--Total users, disabled users, enabled users;
-Consider fetching the following:
--Active Directory:
---Users who's passwords were updated recently.
---Users who's passwords expire within X days.
---Users who's last login timestamp is 30+ days ago.
--O365:
---Users who were deleted that day.
--Exchange:
---User mailbox sizes (in % and GB); (DONE)
---Names/QTY of Shared&User mailboxes (and for shared, who their mail forwards to). (Mailbox and Forwarding Names VERY OPTIONAL)
---Total QTY of mail send&received yesterday/Last 7 days.
---Highest activity mailboxes inbound&outbound.
----------#>

<#----------Change Log:
01/06/23
+ Displaying QTY of disabled users.
+ Displaying QTY of enabled users.
+ Displaying QTY of total users.
+ Displaying QTY of organizational units.
01/08/23
+ Displaying QTY of mailboxes of 'UserMailbox' type.
+ Displaying QTY of mailboxes of 'SharedMailbox' type.
+ Displaying LIST of active exchange mailbox retention policies.
01/10/2023
+ Added a section that scans a targetted list of user mailboxes and pushes out an email to me if the user's mailbox is at or over 95% full.
+ Removed commented out scratch code since intended mailbox monitoring/alert piece has now been realized and built.
+ Added comment explainations throughout for review.
----------#>
    #Connect-ExchangeOnline;
    #--LOGS--#
    $disabledUsersLogDay = "C:\Users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Logs\LLMonitoringTestDisabledUsers.txt";
    $enabledUsersLogDay = "C:\Users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Logs\LLMonitoringTestEnabledUsers.txt";
    $userMailboxesLogDay = "C:\Users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Logs\LLMonitoringTestUserMailboxes.txt";
    $sharedMailboxesLogDay = "C:\Users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Logs\LLMonitoringTestSharedMailboxes.txt";
    $activeRetentionPoliciesLogDay = "C:\Users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Logs\LLMonitoringTestRetentionPolicies.txt";
    #--LOGS--#

    #-QTY of Enabled/Disabled/TotalUsers/OUs-#
    $disabledUsers = (get-aduser -Filter {enabled -eq 'False'}).samaccountname; Sort-Object -Property SamAccountName Get-Date; $disabledUsers | Out-File -FilePath $disabledUsersLogDay -Append;
    $enabledUsers = (get-aduser -Filter {enabled -eq 'True'}).samaccountname; Sort-Object($enabledUsers) -Descending; Get-Date; $enabledUsers | Out-File -FilePath $enabledUsersLogDay -Append;
    $totalUsers = ($disabledUsers.count+$enabledUsers.Count); Sort-Object($totalUsers) -Descending;
    $ADOrganizationalUnits = (Get-ADOrganizationalUnit -filter *).name;

    #-QTY of Shared&User mailboxes. (DONE)
    #--Too many shared mailbox usernames to list automatically. Will consider creating a function to call to generate that list.
    $sharedMailboxes = get-mailbox -filter "recipienttypedetails -eq 'SharedMailbox'"; Get-Date; $sharedMailboxes | Out-File -FilePath $sharedMailboxesLogDay -Append;
    $userMailboxes = get-mailbox -filter "recipienttypedetails -eq 'UserMailbox'"; Get-Date; $userMailboxes | Out-File -FilePath $userMailboxesLogDay -Append;
    
    #-List of retention policies.
    $activeRetentionPolicies = (get-retentionpolicy).name; Get-Date; $activeRetentionPolicies | Out-File -FilePath $activeRetentionPoliciesLogDay -Append;
        foreach ($policy in $activeRetentionPolicies)
            {
                $activeRetentionPoliciesList = $activeRetentionPoliciesList + "$policy, ";
            }
    $UserRetentionPolicies = (get-mailbox).retentionpolicy;

    #-User mailbox sizes (in % and GB); & #-User mailbox X% until full.
    #--Below fetches all of the below properties for ALL active employees and outputs into a list.
    #--Additionally takes the variables containing the used space and the total space, breaks the string down into only the numerical byte #'s, rebuilds it back into the original size,
    #--divides the used bytes by the total bytes and tosses that result (the % full) into a conditional statement within the 'foreach' that pushes an email alert out to me if a user's
    #--mailbox is confirmed to be greater than or equal to 95% full. 
    $SparkhoundEmployees = (get-aduser -Filter {(Company -eq 'Sparkhound') -and (Enabled -eq 'True') -and (EmailAddress -notcontains '*test*')} -Properties emailAddress| sort -property emailAddress).emailAddress
    foreach ($user in $SparkhoundEmployees)
        {
            #Fetching mailbox used size and rebuilding the bytes value to be used in calculations#
            $MailboxUsedSize = (get-mailboxstatistics -Identity $user).totalitemsize.value;
            $NewUsedSize = "$MailboxUsedSize"
            $NewUsedSizeSplit = $NewUsedSize.Split(" "); #Splitting into an array to focus into the byte size easier.
            $UsedSizeStageTwo = $NewUsedSizeSplit[2].Substring(1); #New string removing the '(' character.
            $UsedSizeStageTwoSplit = $UsedSizeStageTwo.Split(","); #Splitting using comma delimmiter to kill the commas.
            $MBUsedSizeFinal = $UsedSizeStageTwoSplit[0]+$UsedSizeStageTwoSplit[1]+$UsedSizeStageTwoSplit[2]+$UsedSizeStageTwoSplit[3]; #Re-joining the array into a string capable of calculations.

            #Fetching mailbox total size and rebuilding the bytes value to be used in calculations#
            $MailboxTotalSize = (get-mailboxstatistics -Identity $user).SystemMessageSizeShutoffQuota.value;
            $NewTotalSize = "$MailboxTotalSize"
            $NewTotalSizeSplit = $NewTotalSize.Split(" "); #Splitting into an array to focus into the byte size easier.
            $TotalSizeStageTwo = $NewTotalSizeSplit[2].Substring(1); #New string removing the '(' character.
            $TotalSizeStageTwoSplit = $TotalSizeStageTwo.Split(","); #Splitting using comma delimmiter to kill the commas.
            $MBTotalSizeFinal = $TotalSizeStageTwoSplit[0]+$TotalSizeStageTwoSplit[1]+$TotalSizeStageTwoSplit[2]+$TotalSizeStageTwoSplit[3]; #Re-joining the array into a string capable of calculations.
            
            #Fetching mailbox deleted size#
            $MailboxDeletedSize = (get-mailboxstatistics -Identity $user).totaldeleteditemsize.Value;


            #Information below used to send email alert#
            $EmailPassFile = get-content -path "C:\users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Pass4.txt"
            $PasswordEmail = ConvertTo-SecureString $EmailPassFile -AsPlainText -Force
            $From = "daniel.landry@sparkhound.com";
            $To = "daniel.landry@sparkhound.com";
            $Port = 587
            $Subject = "Exchange Monitoring Alert [Mailbox Is Over 95% Full]"
            $SMTPserver = "smtp.office365.com"
            $Cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $from, $PasswordEmail
            $Signature = "`n`nThank you,`nLandryLabs`nMonitoring Assistant."


            if ($MBUsedSizeFinal/$MBTotalSizeFinal -le .5)
                {
                    Write-Host " "
                }
            elseif ($MBUsedSizeFinal/$MBTotalSizeFinal -ge .95)
                {   
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
    

    #-Report that I will format to get emailed to me.#
    $Intro = "  #      " 
    $Intro = ($Intro +"|| LANDRY LABS - W.I.P MONITORING REPORT");
    $Intro = ($Intro +"  #      "); 
    $Intro = ($Intro +"|| SUMMARY: ");
    $Intro = ($Intro +"  # #    ");
    $Intro = ($Intro +"|| -------- ");
    $Intro = ($Intro +"  ####   ");
    $Intro = ($Intro +"|| -------- ");
    $Intro = ($Intro +"    #    ");
    $Intro = ($Intro +"|| -------- "); 
    $Intro = ($Intro +"    #### "); 
    $Intro = ($Intro +"|| Written by Daniel Landry (daniel.landry@sparkhound.com)");
    $Date = Get-Date
    Write-Host "Landry Labs Daily Report" $Date;
    Write-Host "ACTIVE DIRECTORY MONITORING:";
    Write-Host "- Enabled User Objects:" $enabledUsers.Count ($enabledUsers.Count/$totalUsers);
    Write-Host "- Disabled User Objects:" $disabledUsers.Count ($disabledUsers.Count/$totalUsers);
    Write-Host "- Organizational Units:" $ADOrganizationalUnits.Count;
    Write-Host "EXCHANGE MONITORING:";
    Write-Host "- Current User Mailboxes " $userMailboxes.Count;
    Write-Host "- current Shared Mailboxes: " $sharedMailboxes.Count;
    Write-Host "- Active Retention Policies: " $activeRetentionPoliciesList;


    <# #Color Formattted Heading#
    Write-Host "  #      " -ForegroundColor DarkGreen -NoNewline
    Write-Host "|| LANDRY LABS - W.I.P MONITORING REPORT";
    Write-Host "  #      " -ForegroundColor DarkGreen -NoNewline
    Write-Host "|| SUMMARY: ";
    Write-Host "  # #    " -ForegroundColor DarkGreen -NoNewline
    Write-Host "|| -------- ";
    Write-Host "  ####   " -ForegroundColor DarkGreen -NoNewline
    Write-Host "|| -------- ";
    Write-Host "    #    " -ForegroundColor DarkGreen -NoNewline
    Write-Host "|| -------- "; 
    Write-Host "    #### " -ForegroundColor DarkGreen -NoNewline
    #>