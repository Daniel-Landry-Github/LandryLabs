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
--Count(NOT list) of Total users, disabled users, enabled users; #This is strictly a analytic proof of concept on pushing easily obtainable stats out as a daily report. There is currently no other reason for monitoring these. 
-Consider fetching the following:
--Active Directory:
---Users who's passwords were updated recently.
---Users who's passwords expire within X days.
---Users who's last login timestamp is 30+ days ago.
--O365:
---Users who were deleted that day.
--AzureAD:
---CAP Monitoring.
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
01/13/2023
+ Adjusted the cmdlet member that obtains the total size of the mailbox to "(get-mailbox).ProhibitSendReceiveQuota" 
    (Ran a test on AFG's exchange mailboxes and ALL 100GB mailboxes were returning as 50GB. Investigated and found the more appropriate value to fetch.)
01/14/2023
+ Dumped existing AAD-CAP list of AAD-CAP 'DisplayName' and 'State' to have as reference for monitoring scans.
+ Added reference code in the test section that fetches all mailboxes that actively have forwarding emailed and to who.
01/15/2023
+ Starting work on the conditional access policy information scans of the Monitoring.
    + Successfully fetches a list of user email addresses in the exclusion list of the 'Block Non-US Acess' policy.
    + Fetching list of included users as well.
----------#>


    #Connect-ExchangeOnline;
    #--LOGS--#
    $disabledUsersLogDay = "C:\Users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Logs\LLMonitoringTestDisabledUsers.txt";
    $enabledUsersLogDay = "C:\Users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Logs\LLMonitoringTestEnabledUsers.txt";
    $userMailboxesLogDay = "C:\Users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Logs\LLMonitoringTestUserMailboxes.txt";
    $sharedMailboxesLogDay = "C:\Users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Logs\LLMonitoringTestSharedMailboxes.txt";
    $activeRetentionPoliciesLogDay = "C:\Users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Logs\LLMonitoringTestRetentionPolicies.txt";
    $MaiboxStatsLog = "C:\Users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Logs\LLMonitoringTestMailboxStats.txt";
    $CAPList = "C:\Users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Logs\LLMonitoringCAPList.txt";
    #--LOGS--#

    #==========^==========#
    # DAILY REPORT INFO
    #==========v==========#
    #-QTY of Enabled/Disabled/TotalUsers/OUs-#
    $disabledUsers = (get-aduser -Filter {enabled -eq 'False'}).samaccountname; Sort-Object -Property SamAccountName Get-Date; $disabledUsers | Out-File -FilePath $disabledUsersLogDay -Append;
    $enabledUsers = (get-aduser -Filter {enabled -eq 'True'}).samaccountname; Sort-Object($enabledUsers) -Descending; Get-Date; $enabledUsers | Out-File -FilePath $enabledUsersLogDay -Append;
    $totalUsers = ($disabledUsers.count+$enabledUsers.Count); Sort-Object($totalUsers) -Descending;
    $ADOrganizationalUnits = (Get-ADOrganizationalUnit -filter *).name;

    #-QTY of Shared&User mailboxes. (DONE)
    $sharedMailboxes = (get-mailbox -filter "recipienttypedetails -eq 'SharedMailbox'" | sort -property emailAddress).emailAddress #Get-Date; $sharedMailboxes | Out-File -FilePath $sharedMailboxesLogDay -Append;
    $userMailboxes = get-mailbox -filter "recipienttypedetails -eq 'UserMailbox'"; Get-Date; $userMailboxes | Out-File -FilePath $userMailboxesLogDay -Append;
    
    #-List of retention policies.
    $activeRetentionPolicies = (get-retentionpolicy).name; Get-Date; $activeRetentionPolicies | Out-File -FilePath $activeRetentionPoliciesLogDay -Append;
        foreach ($policy in $activeRetentionPolicies)
            {
                $activeRetentionPoliciesList = $activeRetentionPoliciesList + "$policy, ";
            }
    $UserRetentionPolicies = (get-mailbox).retentionpolicy;

function MailboxStorageCheck
{
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
          ajones@assurancemortgage.com 
          Used: 92.67 GB (99,505,953,735 bytes)
          Deleted: 48.28 MB (50,624,861 bytes)
          Total: 100 GB (107,374,182,400 bytes)
          Archive Mailbox not enabled.
          ===================
    -Initial build that works as intended. WIll clean up as needed later.
    -Need to see how effectively I can have this in a script that will swap between each IMS Exchange Online shells to run this and push emails out. 
    #>
    $Mailbox = (get-mailbox | sort -property primarysmtpaddress).primarysmtpaddress
    $MBSizeCheck = 0;
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
                    Get-Date; Write-Host " " -NoNewline 
                }
            elseif ($MBUsedSizeFinal/$MBTotalSizeFinal -ge .95)
                {   
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
                    $MBSizeCheck++
                    Send-MailMessage -from $From -To $To -Subject $Subject -Body "$EmailBody`n$signature" -SmtpServer $SMTPserver -Credential $Cred -Verbose -UseSsl -Port $Port
                }  
        }
}
    

    #-Report that I will properly build to get emailed to me.#
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
    $Report = "Landry Labs Daily Report" $Date;
    Write-Host "ACTIVE DIRECTORY MONITORING:";
    Write-Host "- Enabled User Objects:" $enabledUsers.Count ($enabledUsers.Count/$totalUsers);
    Write-Host "- Disabled User Objects:" $disabledUsers.Count ($disabledUsers.Count/$totalUsers);
    Write-Host "- Organizational Units:" $ADOrganizationalUnits.Count;
    Write-Host "EXCHANGE MONITORING:";
    Write-Host "- Current User Mailboxes " $userMailboxes.Count;
    Write-Host "- current Shared Mailboxes: " $sharedMailboxes.Count;
    Write-Host "- Active Retention Policies: " $activeRetentionPoliciesList;




#==========^==========#
#TESTS START#
#==========v==========#
   
function TEST-ADPasswordChanged
{
    #Testing monitoring dates detected within a certain recent range. Ex. Return results with datestamps of 7 days ago.
    #Isolated the 'month', 'day' and 'year' into separate variables to allow direct comparisions and to add/subtract them for ranges.
    #Need to revisit to confirm if I am overthinking a simple solution.
    $SparkhoundEmployees = (get-aduser -Filter {(Company -eq 'Sparkhound') -and (Enabled -eq 'True')}| sort -property samaccountname)
    foreach ($user in $SparkhoundEmployees)
        {
            $Date = Get-Date;
            $dateDay = $Date.AddDays(-30);


            $user = "daniel.landry"
            $passLastSet = (get-aduser -identity $user -properties PasswordLastSet).PasswordLastSet;
            $passLastSetString = "$passLastSet"
            $pLSSplit = $passLastSetString.Split(" ");
            $passLastSetDateSplit = $pLSSplit[0].Split("/");
            $passLastSetDateSplitMonth = $passLastSetDateSplit[0];
            $passLastSetDateSplitDay = $passLastSetDateSplit[1];
            $passLastSetDateSplitYear = $passLastSetDateSplit[2];

            
            if ($passLastSetDateSplitDay -lt $dateDay) 
                {
                    "===================`n"
                    "$user `n";
                    Write-Host "Password Last Set: " -NoNewline $passLastSet;
                    "===================`n"
                }
            else 
            {
            " ";
            }
            <# "===================`n"
            "$user `n";
            Write-Host "Password Last Set: " -NoNewline (get-aduser -identity $user -properties PasswordLastSet).PasswordLastSet;
            $sevenDaysAgo =  Get-Date.days(-7);
            # Write-Host "Last Bad Password Attempt: " -NoNewline (get-aduser -identity $user -properties LastBadPasswordAttempt).LastBadPasswordAttempt "`n"
            # Write-Host "Last Logon Date: " -NoNewline (get-aduser -identity $user -properties LastLogonDate).LastLogonDate "`n"
            # Write-Host "Password Expired: " -NoNewline (get-aduser -identity $user -properties PasswordExpired).PasswordExpired "`n"
            "===================`n" #>
        }
}
       
function TEST-ADAccountLockoutScan
{
     #Fetching locked out accounts.
     $SparkhoundEmployees = (get-aduser -Filter {(Enabled -eq 'True')}).SamAccountName
     foreach ($user in $SparkhoundEmployees)
     {
         $lockedOutStatus = (get-aduser -identity $user -properties lockedout).lockedout;
         

         if ($lockedOutStatus -eq $false)
             {
                 Write-Host " " -NoNewline;
             }
         else 
             {
                 "===================`n"
                 "$user `n"; 
                 Write-Host "Lockout Status: " -NoNewline (get-aduser -identity $user -properties lockedout).lockedout; "`n"
                 "===================`n"

             }

         
     }
}  
   



function TEST-AzureADCapMonitoring
{
    #List AzureAD Conditional Access Policy Information.
    #Scans all CAP entries and compares them against local updated lists and reports any difference to review for authorized/unauthorized changes.

    #Email Alert Block#
    $EmailPassFile = get-content -path "C:\users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Pass4.txt"
    $PasswordEmail = ConvertTo-SecureString $EmailPassFile -AsPlainText -Force
    $From = "daniel.landry@sparkhound.com";
    $To = "daniel.landry@sparkhound.com";
    $Port = 587
    $Subject = " "
    $SMTPserver = "smtp.office365.com"
    $Cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $from, $PasswordEmail
    $Signature = "`n`nThank you,`nLandryLabs`nMonitoring Assistant."
    #Email Alert Block#
        
    $capID = (Get-AzureADMSConditionalAccessPolicy).id
        foreach ($id in $capID)
            {
                
                $capID = "c60d0db5-2b4a-45b8-b22d-db58e02a9ee4"
                $capName = (Get-AzureADMSConditionalAccessPolicy -policyid $capID).DisplayName
                $capState = (Get-AzureADMSConditionalAccessPolicy -policyid $id).State

                #CAP Included Users
                $capConditionIncludedUsers = (Get-AzureADMSConditionalAccessPolicy -policyid $capID).Conditions.Users.IncludeUsers #Fetches list of IncludedUsers
                $capConditionIncludedUseridString = "$capConditionIncludedUsers"; #Converts user list to more of a string to allow better value manupulation.
                $capIncludedUsersIDToEmail = $capConditionIncludedUsers.Clone(); #Mirroring array.
                $i = 0;
                    if ($capConditionIncludedUseridString -eq "All") #Checks if user condition is simply set to "All Users" and skips conversion if so.
                        {
                            $capIncUsersFinal = $capConditionIncludedUseridString;
                        }
                    elseif ($capConditionIncludedUseridString -eq "$Null")
                        {
                            $capIncUsersFinal = $capConditionIncludedUseridString;
                        }
                    else
                        {
                            foreach ($user in $capConditionIncludedUseridString.Split(" "))
                            {
                                $capIncludedUsersIDToEmail[$i] = (get-azureaduser -objectid $user).userprincipalname; #Swapping ID with coresponding email address.
                                $i++
                            }
                            $capIncludedUsersIDToEmailSorted = $capIncludedUsersIDToEmail | sort #Alphabetizes the list for a bit of easier reading.
                            $capIncUsersFinal = $capIncludedUsersIDToEmailSorted;
                        }
                        
                        
                #CAP Excluded Users
                $capConditionExcludedUserid = (Get-AzureADMSConditionalAccessPolicy -policyid $capID).Conditions.Users.ExcludeUsers; #Fetches list of ExcludedUsers
                $capConditionExcludedUseridString = "$capConditionExcludedUserid"; #Converts user list to more of a string to allow better value manupulation.
                $capExcludedUsersIDToEmail = $capConditionExcludedUserid.Clone(); #Mirroring array.
                $i = 0;
                    if ($capConditionExcludedUseridString -eq "All") #Checks if user condition is simply set to "All Users" and skips conversion if so.
                        {
                            $capExcUsersFinal = $capConditionExcludedUseridString;
                        }
                    elseif ($capConditionIncludedUseridString -eq "$Null")
                        {
                            $capIncUsersFinal = $capConditionIncludedUseridString;
                        }
                    else
                        {                    
                            foreach ($user in $capConditionExcludedUseridString.Split(" "))
                                {
                                    $capExcludedUsersIDToEmail[$i] = (get-azureaduser -objectid $user).userprincipalname; #Swapping ID with coresponding email address.
                                    $i++
                                }
                                $capExcludedUsersIDToEmailSorted = $capExcludedUsersIDToEmail | sort #Alphabetizes the list for a bit of easier reading.
                                $capExcUsersFinal = $capExcludedUsersIDToEmailSorted;
                        }
                        

                #CAP Included Groups
                $capConditionIncludedGroups = (Get-AzureADMSConditionalAccessPolicy -policyid $capID).Conditions.Users.IncludeGroups #Fetches list of groups included in the cap.
                
                
                #Report Block
                Write-Host "-Display Name: ";
                Write-Host "--$capName";
                Write-Host "-State:"
                Write-Host "--$capState"
                Write-Host "-Condition: "
                Write-Host "--Included Users: "
                "START--------";
                $capIncUsersFinal;
                "----------END";
                Write-Host "--Excluded Users: ";
                "START--------";
                $capExcUsersFinal;
                "----------END";
                Write-Host "--IncludedGroups: ";
                Write-Host "START--------";
                "$capConditionIncludedGroups"
                Write-Host "----------END";
                #Report Block
                        
            }




        $CAPList = Get-Content -Path "C:\Users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Logs\LLMonitoringCAPList.txt";
        $AZADCAPScan = Get-AzureADMSConditionalAccessPolicy |sort -property state |ft displayname, state
        $AZADCAPScan = "$AZADCAPScan";
        #Compare-Object -ReferenceObject $AZADCAPScan -DifferenceObject $CAPList
            if ($AZADCAPScan -eq $CAPList)
                {
                    Write-Host "Scan completed with no CAP changes detected."
                }
            else 
                {
                    $body = "Scan completed with CAP changes detected.`n";
                    $body = ($body +"Please review the changes below.`n");
                    $body = ($body +"Scan result: `n");
                    $body = ($body +"$AZADCAPScan`n");
                    $body = ($body + "CAP List Reference: `n");
                    $body = ($body +"$CAPList`n");

                    $Subject = "AzureAD Monitoring Alert [Detected changes to Conditional Access Policies]"
                    Send-MailMessage -from $From -To $To -Subject $Subject -Body "$body `n$signature" -SmtpServer $SMTPserver -Credential $Cred -Verbose -UseSsl -Port $Port
                }

    
}
         

        #List of deleted Azure AD groups when applicable:
            Get-AzureADMSDeletedGroup -all $true;

        #Azure Named Location Policies:
            #ID list of ALL named location policies. 
            #Consider storing in a text file and compare against daily/hourly scans to detect new potentially unauthorized named locations.
            #IF a new named location is detected, have a conditional statement use the new ID to fetch the name, policy state, and full IP range list.
            (Get-AzureADMSNamedLocationPolicy).id
            
            #Full list of IP ranges for the 'Non-US Allowed' named location.
            #Consider storing in a text file and compare against daily/hourly scans to detect new potentially unauthorized IP ranges.
            (Get-AzureADMSNamedLocationPolicy -policyid 385d8688-32ae-4d79-9cb0-4f24df7c7a93).IpRanges

        #Last AzureAD Sync Timestamp monitor
            #Consider building an alert that pushes out if this timestamp (UTC +6 hours ahead) hasn't updated in multiple hours.
            (Get-AzureADTenantDetail).CompanyLastDirSyncTime
            

        #Quickly fetch a list of an organization's active mailbox internal/external email forwardings.
            #This code fully works on the exchange tenant currently logged into via connect-exchangeonline.
            #Leaving this here as a reference for now.
            function MailboxesActivelyForwarding
            {
                get-mailbox -Filter {(ForwardingSMTPAddress -ne $null) -or (ForwardingAddress -ne $null)}| ft PrimarySMTPAddress, ForwardingSMTPAddress, ForwardingAddress -AutoSize

            }









#==========^==========#
#TESTS END#
#==========v==========#

    
    
    
    
    