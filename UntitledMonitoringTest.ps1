<#

#      || LANDRY LABS - UNTITLED MONITORING SCRIPT
#      || SUMMARY: T.B.D. 
# #    ||  
####   ||  
  #    || 
  #### || Written by Daniel Landry (daniel.landry@sparkhound.com)

#>

<#
Initial scoping draft for a monitoring project.
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
---User mailbox sizes (in % and GB);
---Names/QTY of Shared&User mailboxes (and for shared, who their mail forwards to). (Mailbox and Forwarding Names VERY OPTIONAL)
---Total QTY of mail send&received yesterday/Last 7 days.
---Highest activity mailboxes inbound&outbound.

#>

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
+ Added a section that scans a targetted list of user mailboxes and pushes out an email to me if the user's mailbox is at or over 95% full.
----------#>
    #Connect-ExchangeOnline;
    #--LOGS--#
    $disabledUsersLogDay = "C:\Users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Logs\LLMonitoringTestDisabledUsers.txt";
    $enabledUsersLogDay = "C:\Users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Logs\LLMonitoringTestEnabledUsers.txt";
    $userMailboxesLogDay = "C:\Users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Logs\LLMonitoringTestUserMailboxes.txt";
    $sharedMailboxesLogDay = "C:\Users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Logs\LLMonitoringTestSharedMailboxes.txt";
    $activeRetentionPoliciesLogDay = "C:\Users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Logs\LLMonitoringTestRetentionPolicies.txt";

    #-QTY of Enabled/Disabled/TotalUsers/OUs-#
    $disabledUsers = (get-aduser -Filter {enabled -eq 'False'}).samaccountname; Sort-Object -Property SamAccountName Get-Date; $disabledUsers | Out-File -FilePath $disabledUsersLogDay -Append;
    $enabledUsers = (get-aduser -Filter {enabled -eq 'True'}).samaccountname; Soft-Object($enabledUsers) -Descending; Get-Date; $enabledUsers | Out-File -FilePath $enabledUsersLogDay -Append;
    $totalUsers = ($disabledUsers.count+$enabledUsers.Count); Sort-Object($totalUsers) -Descending;
    $ADOrganizationalUnits = (Get-ADOrganizationalUnit -filter *).name;

    #-QTY of Shared&User mailboxes. (DONE)
    #--Too many shared mailbox usernames to list automatically. Will consider creating a function to call to generate that list.
    $sharedMailboxes = get-mailbox -filter "recipienttypedetails -eq 'SharedMailbox'"; Get-Date; $sharedMailboxes | Out-File -FilePath $sharedMailboxesLogDay -Append;
    $userMailboxes = get-mailbox -filter "recipienttypedetails -eq 'UserMailbox'"; Get-Date; $userMailboxes | Out-File -FilePath $userMailboxesLogDay -Append;
    $activeRetentionPolicies = (get-retentionpolicy).name; Get-Date; $activeRetentionPolicies | Out-File -FilePath $activeRetentionPoliciesLogDay -Append;
        foreach ($policy in $activeRetentionPolicies)
            {
                $activeRetentionPoliciesList = $activeRetentionPoliciesList + "$policy, ";
            }
    $UserRetentionPolicies = (get-mailbox).retentionpolicy;

    #-User mailbox sizes (in % and GB);
    #--Below fetches all of the below properties for ALL active employees and outputs into a list.
    $SparkhoundEmployees = (get-aduser -Filter {(Company -eq 'Sparkhound') -and (Enabled -eq 'True') -and (EmailAddress -notcontains '*test*')} -Properties emailAddress| sort -property emailAddress).emailAddress
    foreach ($user in $SparkhoundEmployees)
        {
            #Mailbox > TotalItemSize.Value#
            $MailboxUsedSize = (get-mailboxstatistics -Identity $user).totalitemsize.value;
            $NewUsedSize = "$MailboxUsedSize"
            $NewUsedSizeSplit = $NewUsedSize.Split(" "); #Splitting into an array to focus into the byte size easier.
            #$NewUsedSizeSplit[2]; #Array entry that contains the size in bytes.
            $UsedSizeStageTwo = $NewUsedSizeSplit[2].Substring(1); #New string removing the '(' character.
            $UsedSizeStageTwoSplit = $UsedSizeStageTwo.Split(","); #Splitting using comma delimmiter to kill the commas.
            $MBUsedSizeFinal = $UsedSizeStageTwoSplit[0]+$UsedSizeStageTwoSplit[1]+$UsedSizeStageTwoSplit[2]+$UsedSizeStageTwoSplit[3]; #Re-joining the array into a string capable of calculations.

            #Mailbox > SystemMessageSizeShutOffQuota.Value#
            $MailboxTotalSize = (get-mailboxstatistics -Identity $user).SystemMessageSizeShutoffQuota.value;
            $NewTotalSize = "$MailboxTotalSize"
            $NewTotalSizeSplit = $NewTotalSize.Split(" "); #Splitting into an array to focus into the byte size easier.
            #$NewTotalSizeSplit[2]; #Array entry that contains the size in bytes.
            $TotalSizeStageTwo = $NewTotalSizeSplit[2].Substring(1); #New string removing the '(' character.
            $TotalSizeStageTwoSplit = $TotalSizeStageTwo.Split(","); #Splitting using comma delimmiter to kill the commas.
            $MBTotalSizeFinal = $TotalSizeStageTwoSplit[0]+$TotalSizeStageTwoSplit[1]+$TotalSizeStageTwoSplit[2]+$TotalSizeStageTwoSplit[3]; #Re-joining the array into a string capable of calculations.
            
            #Mailbox > TotalDeletedItemSize.Value#
            $MailboxDeletedSize = (get-mailboxstatistics -Identity $user).totaldeleteditemsize.Value;


            #Mailing info below
            #$LandryLabsBotPassFile = get-content -path "C:\users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Pass3.txt"
            #$PasswordLandryLabs = ConvertTo-SecureString $LandryLabsBotPassFile -AsPlainText -Force
            $EmailPassFile = get-content -path "C:\users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Pass4.txt"
            $PasswordEmail = ConvertTo-SecureString $EmailPassFile -AsPlainText -Force
            $From = "daniel.landry@sparkhound.com";
            $To = "daniel.landry@sparkhound.com";
            $Port = 587
            $Subject = "MONITORING ALERT WARNING [MAILBOX IS OVER 95% FULL!]"
            $SMTPserver = "smtp.office365.com"
            $Cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $from, $PasswordEmail
            $Signature = "`n`nThank you,`nLandryLabs Bot`nMonitoring Assistant."

            if ($MBUsedSizeFinal/$MBTotalSizeFinal -le .5)
                {
                    Write-Host " "
                }
            elseif ($MBUsedSizeFinal/$MBTotalSizeFinal -ge .95)
                {   
                    #$EmailBody = "WARNING - MAILBOX IS OVER 95% FULL!`n`n"
                    $EmailBody = "===================`n"
                    $EmailBody = ($EmailBody +"$user `n"); 
                    $EmailBody = ($EmailBody +"Used: "+$MailboxUsedSize+"`n");
                    $EmailBody = ($EmailBody +"Deleted: "+$MailboxDeletedSize+"`n");
                    $EmailBody = ($EmailBody +"Total: "+$MailboxTotalSize+"`n");
                        if ((get-mailbox -Identity $user).ArchiveStatus -eq 'None')
                            {
                                $EmailBody = ($EmailBody +"Archive Mailbox not enabled.`n");
                            }
                        elseif ((get-mailbox -identity $user).ArchiveStatus -eq 'Active') 
                            {
                                $EmailBody = ($EmailBody +"Archive: "+(get-mailbox -Identity $user).ArchiveStatus);
                                $EmailBody = ($EmailBody +"Archive Used: "+(get-mailboxstatistics $user -Archive).totalitemsize.Value);
                                $EmailBody = ($EmailBody +"Archive Deleted: "+(get-mailboxstatistics $user -Archive).totaldeleteditemsize.Value);
                            }
                    $EmailBody = ($EmailBody +"===================`n")
                    Send-MailMessage -from $From -To $To -Subject $Subject -Body "$EmailBody`n$signature" -SmtpServer $SMTPserver -Credential $Cred -Verbose -UseSsl -Port $Port
                }

            <# "==================="
            Write-Host "$user "; 
            Write-Host "Used: " -NoNewline (get-mailboxstatistics -Identity $user).totalitemsize.value;" ";
            Write-Host "Deleted: " -NoNewline (get-mailboxstatistics -Identity $user).totaldeleteditemsize.value;" ";
            Write-Host "Total: " -NoNewline (get-mailboxstatistics -Identity $user).SystemMessageSizeShutoffQuota.Value;" ";
                if ((get-mailbox -Identity $user).ArchiveStatus -eq 'None')
                    {
                        Write-Host "Archive Mailbox not enabled."
                    }
                elseif ((get-mailbox -identity $user).ArchiveStatus -eq 'Active') 
                    {
                        Write-Host "Archive: " -NoNewline (get-mailbox -Identity $user).ArchiveStatus;" ";
                        Write-Host "Archive Used: " -NoNewline (get-mailboxstatistics $user -Archive).totalitemsize.Value;" ";
                        Write-Host "Archive Deleted: " -NoNewline (get-mailboxstatistics $user -Archive).totaldeleteditemsize.Value;" ";
                    }
            "===================" #>

            <#Write-Host "WARNING - MAILBOX IS 95% FULL!"
                    "==================="
                    Write-Host "$user "; 
                    Write-Host "Used: " -NoNewline (get-mailboxstatistics -Identity $user).totalitemsize.value;" ";
                    Write-Host "Deleted: " -NoNewline (get-mailboxstatistics -Identity $user).totaldeleteditemsize.value;" ";
                    Write-Host "Total: " -NoNewline (get-mailboxstatistics -Identity $user).SystemMessageSizeShutoffQuota.Value;" ";
                        if ((get-mailbox -Identity $user).ArchiveStatus -eq 'None')
                            {
                                Write-Host "Archive Mailbox not enabled."
                            }
                        elseif ((get-mailbox -identity $user).ArchiveStatus -eq 'Active') 
                            {
                                Write-Host "Archive: " -NoNewline (get-mailbox -Identity $user).ArchiveStatus;" ";
                                Write-Host "Archive Used: " -NoNewline (get-mailboxstatistics $user -Archive).totalitemsize.Value;" ";
                                Write-Host "Archive Deleted: " -NoNewline (get-mailboxstatistics $user -Archive).totaldeleteditemsize.Value;" ";
                            }
                    "==================="#>
        }
    #--User mailbox X% until full.
    #Take the existing output from 'SparkhoundEmployees > Mailbox > TotalItemSize.Value' and locate the index of the '(' and 'b' characters are to get the index range
    #-that can isolate the full bytes size. Ex '('...9,246,274,107...'b'ytes). Then remove the ',' formatting to allow it to be added to a calculation.
    #TESTING#
    $MailboxUsedSize = (get-mailboxstatistics -Identity daniel.landry@sparkhound.com).totalitemsize.value;
    $NewUsedSize = "$MailboxUsedSize"
    $NewUsedSizeSplit = $NewUsedSize.Split(" "); #Splitting into an array to focus into the byte size easier.
    #$NewUsedSizeSplit[2]; #Array entry that contains the size in bytes.
    $UsedSizeStageTwo = $NewUsedSizeSplit[2].Substring(1); #New string removing the '(' character.
    $UsedSizeStageTwoSplit = $UsedSizeStageTwo.Split(","); #Splitting using comma delimmiter to kill the commas.
    $UsedSizeStageTwoSplit[0]+$UsedSizeStageTwoSplit[1]+$UsedSizeStageTwoSplit[2]+$UsedSizeStageTwoSplit[3]; #Re-joining the array into a string capable of calculations.
    
    $MailboxTotalSize = (get-mailboxstatistics -Identity daniel.landry@sparkhound.com).SystemMessageSizeShutoffQuota.value;
    $NewTotalSize = "$MailboxTotalSize"
    $NewTotalSizeSplit = $NewTotalSize.Split(" "); #Splitting into an array to focus into the byte size easier.
    #$NewTotalSizeSplit[2]; #Array entry that contains the size in bytes.
    $TotalSizeStageTwo = $NewTotalSizeSplit[2].Substring(1); #New string removing the '(' character.
    $TotalSizeStageTwoSplit = $TotalSizeStageTwo.Split(","); #Splitting using comma delimmiter to kill the commas.
    $TotalSizeStageTwoSplit[0]+$TotalSizeStageTwoSplit[1]+$TotalSizeStageTwoSplit[2]+$TotalSizeStageTwoSplit[3]; #Re-joining the array into a string capable of calculations.
    

    $MBPercentFull = ($UsedSizeStageTwoSplit[0]+$UsedSizeStageTwoSplit[1]+$UsedSizeStageTwoSplit[2]+$UsedSizeStageTwoSplit[3]) / ($TotalSizeStageTwoSplit[0]+$TotalSizeStageTwoSplit[1]+$TotalSizeStageTwoSplit[2]+$TotalSizeStageTwoSplit[3])
    $MBPercentFull


    
    #$MailboxUsedSizeString = "$MailboxUsedSize";
    #Write-Host "======";
    #$MailboxUsedSizeString.IndexOf("4");



    Write-Host "  #      " -ForegroundColor DarkGreen -NoNewline
    Write-Host "|| LANDRY LABS - W.I.P DAILY MONITORING REPORT";
    Write-Host "  #      " -ForegroundColor DarkGreen -NoNewline
    Write-Host "|| SUMMARY: ";
    Write-Host "  # #    " -ForegroundColor DarkGreen -NoNewline
    Write-Host "|| -------- ";
    Write-Host "  ####   " -ForegroundColor DarkGreen -NoNewline
    Write-Host "|| -------- ";
    Write-Host "    #    " -ForegroundColor DarkGreen -NoNewline
    Write-Host "|| -------- "; 
    Write-Host "    #### " -ForegroundColor DarkGreen -NoNewline
    Write-Host "|| Written by Daniel Landry (daniel.landry@sparkhound.com)"
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
