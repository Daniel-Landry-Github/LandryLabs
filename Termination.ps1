<#
#      || TERMINATION SCRIPT
#      || SUMMARY: 1. Disables user object, logs properties/groups and wipes them, 
# #    || -------- 2. Moves user object to designated OU for disabled user objects. 
####   || -------- 3. Blocks O365 sign-in, converts mailbox to shared, revokes licenses. 
  #    || 
  #### || 
LANDRY ||
 LABS  || Written by Daniel Landry (daniel.landry@sparkhound.com)
#>

<#----------TO DO:
-BUILD:
--Revoke any licenses NOT inhereted by groups.
--Log user properties right before account is disabled.
--Forward mailbox email to target forward user if requested.
--CWMNote section at the end of script detailing summary of what was done.

-FIX:

-IMPROVE:
--Add variable for Connectwise Ticket # for reference.
----------#>

<#----------Change Log:
01/04/23
o Moved all credential variables into a section labeled "Non-user Credentials"
o Adjusted the variables '$userPath', '$userEnabledStatus', and '$Name' to only request the default properties OR default and that additional property since none of them require fetching the full properties list.
o Adjusted the labeling of each step to allow better visibility.
+ Takes entered username and verifies it against existing AD users before proceeding further.
+ Created a function called 'Program' containing a greeting summary of the script, asking the user to confirm that they want to continue or exit.
+ Created a function called 'RequestTermInfo' that groups the username request and verification against AD in one function before proceeding.
- Removed 'RequestTermInfo' as a function for now and back in line on the main script due to the variables and their values NOT carrying over to the main script to be further referenced.
+ Added 'Do-While' loop to ensure a valid username is submitted.
----------#>




$date = Get-Date -UFormat "%D %r"
$DisabledOU = 'OU=Disabled Accounts,DC=sparkhound,DC=com'

#==========^==========#
#START OF FUNCTIONS
#==========V==========#
Function Program #SCRIPT GREETING AND REQUESTING CONFIRMATION TO START TERM OR EXIT.
    {
        Write-Host "  #      " -ForegroundColor DarkGreen -NoNewline
        Write-Host "|| LANDRY LABS - TERMINATION SCRIPT"
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

    
<#function RequestTermInfo #REQUESTING AND VERIFYING USER INFORMATION BEFORE TERM.
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
            
    }#>
    
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
    }        

#==========^==========#
#END OF FUNCTIONS
#==========V==========#


       
Program; #Script starts interaction with this 'Program' function.


#==========^==========#
#REQUEST AND VERIFY USER INFORMATION
#==========V==========#
    do 
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
                    "Proceeding to disable user...";
                    $Verified = "Y"
                }
            else
                {
                    $Verified = "N"
                    "Username not found. Please enter a valid username."
                }
        }
    Until ($Verified -eq "Y")

#==========^==========#
#STEP 1: DISABLE THE USER OBJECT
#==========V==========#
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

#==========^==========#
#STEP 2: LOG AND WIPE ON-PREM AD GROUPS (Add cloud groups?)
#==========V==========#
$userGroups = (get-aduser -Identity $username -properties *).Memberof
"Fetching groups list..."
"----------"
    foreach ($UserGroupEntry in $userGroups)
        {
            "`nRemoving $username from $UserGroupEntry..."
            #Remove-ADGroupMember -identity $UserGroupEntry -member $username -Confirm:$false
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
        }
#==========^==========#
#STEP 3: WIPE MANAGER
#==========V==========#
$managername = (get-aduser -identity $username -properties *).manager
$manager = (get-aduser -identity $managername -properties *).samaccountname
"Unassigning user from $manager..."; sleep 3
set-aduser -identity $username -clear Manager;
    if ($manager = "null") 
        {
            "Unassigned..."
        } 
    else 
        {
            "Unable to unassign $username from $manager"
        }
    sleep 3

#==========^==========#
#STEP 4: WIPE DATE OF BIRTH & DATE OF HIRE EXTENDED ATTRIBUTES
#==========V==========#
$DateofBirth = (get-aduser -identity $username -properties *).extensionattribute1
"Wiping date of birth ($DateofBirth)..."
set-aduser -identity $username -Clear ExtensionAttribute1; sleep 3
    if ($DateofBirth = "null") 
        {
            "Wiped."
        } 
    else 
        {
            "Unable to wipe date of birth."
        }

$DateofHire = (get-aduser -identity $username -properties *).extensionattribute2
"Wiping date of hire ($DateofHire)..."; sleep 3
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
#STEP 5: MOVE USER OBJECT TO DISABLED USER OU
#==========V==========#
"Moving $username to designated OU for disabled objects."
$Name = (get-aduser -identity $username -properties *).cn
$UserPath = (get-aduser -identity $username -properties *).distinguishedname
move-adobject -identity $UserPath -targetpath "OU=Disabled Accounts,DC=sparkhound,DC=com"
$UserDisabledPath = ("CN=$Name,"+$DisabledOU)
    if ($UserPath -eq $UserDisabledPath) 
        {
            "Object moved successfully."
        } 
    else
        {
            "Object move failed"
        };

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



