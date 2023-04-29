<#

#      || LANDRY LABS - TERMINATION SCRIPT
#      || SUMMARY: 1. Disables user object, logs properties/groups and wipes them, 
# #    || -------- 2. Moves user object to designated OU for disabled user objects. 
####   || -------- 3. Blocks O365 sign-in, converts mailbox to shared, revokes licenses. 
  #    || 
  #### || Written by Daniel Landry (daniel.landry@sparkhound.com)

#>

<#----------TO DO:
-BUILD:
-FIX:
-IMPROVE:
----------#>

<#----------Change Log:
----------#>


$Host.UI.RawUI.WindowTitle = "Sparkhound Termination v1.5"

#==========^==========#
#START OF FUNCTIONS
#==========V==========#
Function Program #SCRIPT GREETING AND REQUESTING CONFIRMATION TO START TERM OR EXIT.
    {
        Write-Host "  #      " -ForegroundColor DarkGreen -NoNewline
        Write-Host "|| LANDRY LABS - TERMINATION SCRIPT (Updated 03/29/2023)"
        Write-Host "  #      " -ForegroundColor DarkGreen -NoNewline
        Write-Host "|| SUMMARY: 1. Disables user object, logs properties/groups and wipes them,"
        Write-Host "  # #    " -ForegroundColor DarkGreen -NoNewline
        Write-Host "|| -------- 2. Moves user object to designated OU for disabled user objects."
        Write-Host "  ####   " -ForegroundColor DarkGreen -NoNewline
        Write-Host "|| -------- 3. Blocks O365 sign-in, converts mailbox to shared, revokes licenses. "
        Write-Host "    #    " -ForegroundColor DarkGreen -NoNewline
        Write-Host "|| " 
        Write-Host "    #### " -ForegroundColor DarkGreen -NoNewline
        Write-Host "|| Written by Daniel Landry (daniel.landry@sparkhound.com)"
        $Begin = Read-Host "Enter 'Y' to begin a termination. Enter 'N' to exit"
            do 
                {
                    if ($Begin -eq "Y")
                        {
                            return;
                            
                        }
                    elseif ($Begin -eq "N")
                        {
                            exit;
                        }
                    else
                        {
                            "Invalid option."
                            Program;
                        }
                }
            until ($Begin -eq "Y" -or $Begin -eq "N") 
     }

#==========^==========#
#END OF FUNCTIONS
#==========V==========#



Program; #Script starts interaction with this 'Program' function.
Start-Transcript -Path "$(Get-Location)\Terminations\TerminationTranscript.txt"
$Date = Get-Date
$DisabledOU = 'OU=Disabled Accounts,DC=sparkhound,DC=com'
$TimeStart = Get-Date;
Connect-AzureAD 
Connect-ExchangeOnline
#==========^==========#
#REQUEST AND VERIFY USER
#==========V==========#
    do 
        {
            "--START 'REQUEST & VERIFY' LOG--`n"
            $username = Read-Host "Enter username (First.Last)"
            "LOG: SUBMITTED USERNAME: $username"        
            $userVerificaiton = (get-aduser -filter {samaccountname -like $username}).samaccountname
            "LOG: VERIFICATION RESULTS: $userVerification" 
            if ($userVerificaiton -eq $username)
                {
                    "Account confirmed! Fetching information..."
                    $Name = (get-aduser -identity $username -properties cn).cn
                    $UserPath = (get-aduser -identity $username).distinguishedname
                    $UserPathConvert = "$userPath" 
                    $UserPathConvert 
                    $EmailAddress = "$username@sparkhound.com" 
                    $UserVerified = "Y"
                    get-aduser -identity $username -properties *
                }
            else
                {
                    $UserVerified = "N" 
                    "$username not found. Please enter a valid username."
                }
        }
    Until ($UserVerified -eq "Y")

#==========^==========#
#REQUEST AND VERIFY MAILBOX FORWARDING TARGET
#==========V==========#
    Do
        {
            $MailboxForwarding = Read-Host "Forwarding $username's email to another mailbox? (Enter 'Y'/'N')"
            "LOG: Forwarding set to $MailboxForwarding"
                If ($MailboxForwarding -eq 'Y')
                    {
                        $MailboxForwardingAddress = Read-Host "Please enter the email address to forward to"
                        $verifyForwardingTarget = (get-aduser -filter {userprincipalname -like $MailboxForwardingAddress}).userprincipalname
                            
                            if ($verifyForwardingTarget -eq $EmailAddress)
                                {
                                    $ForwardingVerified = "N"
                                    "Forwarding address can not be the same as the termed user's address. Try again."
                                }
                            elseif ($verifyForwardingTarget -eq $MailboxForwardingAddress)
                                {
                                    $ForwardingVerified = "Y"
                                    "Forwarding address confirmed! Proceeding."
                                }
                            else
                                {
                                    $ForwardingVerified = "N"
                                    "Submitted address doesn't match to an active address."
                                }
                    }
                elseif ($MailboxForwarding -eq 'N')
                    {
                        $ForwardingVerified = "Y"
                        "No email forwarding will take place."
                    }
                else
                    {
                        $ForwardingVerified = "N"
                        "Submission invalid. Please enter either 'Y' or 'N' to continue."
                    }
        }
    Until ($ForwardingVerified -eq "Y")

#==========^==========#
#STEP 1: DISABLE THE USER OBJECT
#==========V==========#
"Checking on-prem enabled status..."
$userEnabledStatus = (Get-aduser -Identity $username).Enabled
    If ($userEnabledStatus = "true") 
        {
            "$username is currently enabled. Disabling..."
            set-aduser -identity $username -Enabled $false
            "$username is now disabled."
        }
    else 
        {
            "$username is already disabled...Proceeding."
        }
Start-Sleep 2
#==========^==========#
#STEP 6: BLOCK O365 SIGN-IN ACCESS
#==========V==========#
"Detecting O365 sign-in access."
$O365EnabledCheck = (Get-AzureADUser -ObjectId $EmailAddress).accountenabled
    if ($O365EnabledCheck -eq "True") 
        {
            "Access enabled. Disabling..."; 
            Set-AzureADUser -objectid $EmailAddress -AccountEnabled:$false
        } 
    else 
        {
            "Access already disabled. Proceeding..."
        }
#==========^==========#
#STEP 2: LOG AND WIPE ON-PREM AD GROUPS (Add cloud groups?)
#==========V==========#
"Fetching active on-prem groups..."
$userGroups = (get-aduser -Identity $username -properties *).Memberof
$userGroupsCount = $userGroups.Count;
Write-Host "Fetching groups list..." -NoNewline;
Write-Host "----------" -NoNewline;
Write-Host " $userGroupsCount on-prem groups found."
$i = 1;
    foreach ($UserGroupEntry in $userGroups)
        {
            "`n($i/$userGroupsCount) Removing $username from $UserGroupEntry..."
            Remove-ADGroupMember -identity $UserGroupEntry -member $username -Confirm:$false
            $userGroupRemovedVerify = (Get-ADGroupMember -Identity $UserGroupEntry).samaccountname
            foreach ($PostRemovedGroupMembers in $userGroupRemovedVerify)
            {
                if ($PostRemovedGroupMembers -eq $username)
                    {
                        "`nUser is still in group. Removal failed...Skipping."
                    }
                else 
                    {
                        Write-host -NoNewline " " 
                    }
            }
            ++$i
        }
#==========^==========#
#STEP 3: WIPE MANAGER
#==========V==========#
$managername = (get-aduser -identity $username -properties *).manager
$manager = (get-aduser -identity $managername -properties *).samaccountname
"Unassigning user from $manager's direct report..."; Start-Sleep 2
set-aduser -identity $username -clear Manager;
    if ($manager = "null") 
        {
            "Unassigned..."
        } 
    else 
        {
            "Unable to unassign $username from $manager"
        }
    Start-Sleep 2
#==========^==========#
#STEP 4: WIPE DATE OF BIRTH & DATE OF HIRE EXTENDED ATTRIBUTES
#==========V==========#
$DateofBirth = (get-aduser -identity $username -properties *).extensionattribute1
"Wiping date of birth ($DateofBirth)..."
set-aduser -identity $username -Clear ExtensionAttribute1; Start-Sleep 2
    if ($DateofBirth = "null") 
        {
            "Wiped."
        } 
    else 
        {
            "Unable to wipe date of birth."
        }

$DateofHire = (get-aduser -identity $username -properties *).extensionattribute2
"Wiping date of hire ($DateofHire)..."; Start-Sleep 2
set-aduser -Identity $username -Clear ExtensionAttribute2
    if ($DateofHire = "null") 
        {
            "Wiped."
        } 
    else 
        {
            "Unable to wipe date of hire."
        }
#==========^==========#
#STEP 7: CONVERT MAILBOX TO SHARED
#==========V==========#
"Checking for mailbox type (Shared/User)."
$MailboxStateCheck = (get-mailbox $EmailAddress).recipienttypedetails
    if ($MailboxStateCheck -eq "UserMailbox")
        {
            "Confirmed to be 'user' mailbox..."
            set-mailbox -identity $EmailAddress -type Shared
            "Converted to 'shared'."
        } 
    else
        {
            "Mailbox is already 'shared'."
        }

#==========^==========#
#STEP 8: LOG AND REVOKE ALL LICENSES
#==========V==========#
"Checking licenses to revoke..."
$MailboxGroup = (get-azureadgroup -SearchString "sg.microsoft 365 Business Premium (Cloud Group)").objectid
$MailboxGroupList = get-azureadgroupmember -objectid $MailboxGroup | ft userprincipalname
    foreach ($user in $MailboxGroupList)
        {
            if ($user -eq $EmailAddress)
                {
                    $NewUserObjectID = (get-azureaduser -filter "userprincipalname eq '$EmailAddress'").objectid
                    Remove-AzureADGroupMember -objectid "$MailboxGroup" -MemberId "$NewUserObjectID";
                }
            else
                {
                    Write-Host " " -NoNewline
                }
        }

#==========^==========#
#STEP 5: MOVE USER OBJECT TO DISABLED USER OU
#==========V==========#
"Moving $username to designated OU for disabled objects ($DisabledOU)."
$Name = (get-aduser -identity $username -properties *).cn
$UserPath = (get-aduser -identity $username -properties *).distinguishedname
move-adobject -identity $UserPath -targetpath "OU=Disabled Accounts,DC=sparkhound,DC=com"
$UserDisabledPath = ("CN=$Name,"+ "$DisabledOU")
    if ($UserPath -eq $UserDisabledPath) 
        {
            "Object moved successfully."
        } 
    else
        {
            "Object move failed"
        };

#==========^==========#
#STEP 9: ENABLE EMAIL FORWARDING (IF APPLICABLE)
#==========V==========#
if ($MailboxForwarding -eq 'Y')
        {
            Write-Host "Configuring $EmailAddress to forward to $MailboxForwardingAddress"
            set-mailbox $EmailAddress -ForwardingAddress $MailboxForwardingAddress
            #Send forwarding test email
            $EmailPass = "*REMOVED*"
            $PasswordEmail = ConvertTo-SecureString $EmailPass -AsPlainText -Force
            $from = "landrylabs.bot@sparkhound.com";
            $ToForwarding = "$MailboxForwardingAddress";
            #$Cc = "daniel.landry@sparkhound.com";
            Cc = "mi-t2@sparkhound.com";
            $Port = 587
            $Subject = "Sending Forwarding Test For Termed User $EmailAddress."
            $SMTPserver = "smtp.office365.com"
            $Cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $from, $PasswordEmail
            $Signature = "`n`nThank you,`nLandryLabs `nAutomation Assistant `nQuestions? Email 'mi-t2@sparkhound.com'."
            Write-Host "Sending Forwarding test email now to $MailboxForwardingAddress."

            $Note = "$EmailAddress has been disabled and pushing test email out to confirm email forwarding is properly active."
            Send-MailMessage -from $From -To $ToForwarding -Cc $Cc -Subject $Subject -Body "$Note`n$signature" -SmtpServer $SMTPserver -Credential $Cred -Verbose -UseSsl -Port $Port
        }
$TimeEnd = Get-Date;
Stop-Transcript

$LOGFile = Get-Content -Path "$(Get-Location)\Terminations\TerminationTranscript.txt"
$LOGArray = @()
    foreach ($item in $LOGFile)
        {
            $LogArray += "$item`n";
        }

#Mailing info below
$EmailPass = "*REMOVED*"
$PasswordEmail = ConvertTo-SecureString $EmailPass -AsPlainText -Force
$From = "landrylabs.bot@sparkhound.com";
$To = "mi-t2@sparkhound.com";
#$To = "daniel.landry@sparkhound.com";
$Port = 587
$Subject = "Account Termination - Complete | $EmailAddress."
$SMTPserver = "smtp.office365.com"
$Cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $from, $PasswordEmail
$Signature = "`n`nThank you,`nLandryLabs `nAutomation Assistant `nTermination Questions? Email 'mi-t2@sparkhound.com'"



#==========^==========#
#Technician note for CWM ticket/HR..
#==========V==========#
$CWMnote = "Start Time: $TimeStart`n"
$CWMnote = ($CWMnote + "End Time: $TimeEnd`n");
$CWMnote = ($CWMnote + "Generated note for ConnectwiseManage ticket below`n")
$CWMnote = ($CWMnote + "====================`n")
$CWMnote = ($CWMnote + "Hello HR,`n");
$CWMnote = ($CWMnote + "$Name's Active Directory account is disabled.`n");
$CWMnote = ($CWMnote + "O365 sign in access is blocked.`n");
$CWMnote = ($CWMnote + "All AD security groups, manager, date of birth, and date of hire have been wiped`n");
$CWMnote = ($CWMnote + "Mailbox has been converted to 'shared'`n");
$CWMnote = ($CWMnote + "Reassigned to OU for disabled users: $DisabledOU`n");
$CWMnote = ($CWMnote + "Emails are being forwarded to '$MailboxForwardingAddress'`n");
$CWMnote = ($CWMnote + "====================`n");
$CWMnote
$LogTranscriptStart = "TRANSCRIPT BELOW"
Send-MailMessage -from $From -To $To -Subject $Subject -Body "$CWMnote`n$LogTranscriptStart`n$LOGArray`n$signature" -SmtpServer $SMTPserver -Credential $Cred -Verbose -UseSsl -Port $Port




<#
function RequestTermInfo #REQUESTING AND VERIFYING USER INFORMATION BEFORE TERM.
    {
        $username = Read-Host "Enter username (First.Last)"
        
        $verifyUserExists = (get-aduser -filter {samaccountname -like $username}).samaccountname
        if ($verifyUserExists -eq $username)
            {
                "Account confirmed! Fetching information..."
                $Name = (get-aduser -identity $username -properties cn).cn
                $UserPath = (get-aduser -identity $username).distinguishedname
                $UserPathConvert = "$userPath"
                $UserPathConvert
                $EmailAddress = "$username@sparkhound.com"
                "Proceeding to disable user..."
                return $username, $name, $userPath, $UserPathConvert, $EmailAddress;
                #DisableUser; #Moving to disable the user.
            }
        else
            {
                "Username not found. Please enter a valid username."
                RequestTermInfo;
            }
            
    }
    
Function DisableUser
    {
        $userEnabledStatus = (Get-aduser -Identity $username).Enabled
            If ($userEnabledStatus = "true") 
                {
                    "$username is currently enabled. Disabling..."
                    set-aduser -identity $username -Enabled $false
                    "$username is now disabled."
                }
            else 
                {
                    "$username is already disabled...Proceeding."
                }
    }#>

