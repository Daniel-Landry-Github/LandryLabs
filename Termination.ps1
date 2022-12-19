#Termination Script by Daniel Landry


<#----------Change Log:
+ Added instructions to detect, remove, and verify removal of the AD security groups of the user.
----------#>


$date = Get-Date -UFormat "%D %r"

##Script Start
$username = Read-Host "Enter username (First.Last)"

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








#$user = get-aduser -Identity daniel.landry -properties *
#$userManager = $user.manager
#$userManager
#Step 4: Discover user's "Date of Birth" and "Date of Hire" entries in extended attributes and remove them.
#Step 5: Move the user object to Disabled Users OU.
#Step 6: Block O365 sign-in.
#Step 7: Convert Exchange Mailbox to 'shared' from 'user'.
#Step 8: Revoke any licenses NOT inhereted by groups.