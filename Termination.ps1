#Termination Script by Daniel Landry


<#----------Change Log:
+ Detects, removes, and verifies removal of the AD security groups of the user.
+ Unassignes user from assigned Manager.
+ Wipes Date of Birth and Date of Hire from Extended Attributes.
+ Moves user to the OU for disabled users.
----------#>


$date = Get-Date -UFormat "%D %r"
$DisabledOU = 'OU=Disabled Accounts,DC=sparkhound,DC=com'

##Script Start
$username = Read-Host "Enter username (First.Last)"
$Name = (get-aduser -identity $username -properties *).cn
$UserPath = (get-aduser -identity $username -properties *).distinguishedname
$UserPathConvert = "$userPath"
$UserPathConvert

"Starting termination task on user $username..."
#Step 1: Disable the user object. *DONE*
$userEnabledStatus = (Get-aduser -Identity $username -properties *).Enabled
If ($userEnabledStatus = "true") {
    "$username is currently enabled. Disabling..."
    set-aduser -identity $username -Enabled $false
    "$username is now disabled."
}
else {
    "$username is already disabled...Proceeding."
    }


#Step 2: Discover user's on-prem AD groups, log them, then remove them. *WIP*
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
        else {Write-host -NoNewline " " }
    }
}

#Step 3: Discover user's manager and delete from user object.
$username = "dan.doe"
$managername = (get-aduser -identity $username -properties *).manager
$manager = (get-aduser -identity $managername -properties *).samaccountname
"Unassigning user from $manager..."; sleep 3
set-aduser -identity $username -clear Manager;
if ($manager = "null") {"Unassigned..."} else {"Unable to unassign $username from $manager"}
sleep 3

#Step 4: Discover user's "Date of Birth" and "Date of Hire" entries in extended attributes and remove them.
$DateofBirth = (get-aduser -identity $username -properties *).extensionattribute1
"Wiping date of birth ($DateofBirth)..."
set-aduser -identity $username -Clear ExtensionAttribute1; sleep 3
if ($DateofBirth = "null") {"Wiped."} else {"Unable to wipe date of birth."}

$DateofHire = (get-aduser -identity $username -properties *).extensionattribute2
"Wiping date of hire ($DateofHire)..."; sleep 3
set-aduser -Identity $username -Clear ExtensionAttribute2
if ($DateofHire = "null") {"Wiped."} else {"Unable to wipe date of hire."}



#Step 5: Move the user object to Disabled Users OU.
"Moving $username to designated OU for disabled objects."
$Name = (get-aduser -identity $username -properties *).cn
$UserPath = (get-aduser -identity $username -properties *).distinguishedname
move-adobject -identity $UserPath -targetpath "OU=Disabled Accounts,DC=sparkhound,DC=com"
$UserDisabledPath = ("CN=$Name,"+$DisabledOU)
if ($UserPath -eq $UserDisabledPath) {"Object moved successfully."} else{"Object move failed"};




#Step 6: Block O365 sign-in.
#Step 7: Convert Exchange Mailbox to 'shared' from 'user'.
#Step 8: Revoke any licenses NOT inhereted by groups.