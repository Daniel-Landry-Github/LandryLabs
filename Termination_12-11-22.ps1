#Termination Script by Daniel Landry
$date = Get-Date -UFormat "%D %r"

##Script Start
$username = Read-Host "Enter username (First.Last)"
#"$date | Starting termination task on user $username..." 
#| out-file 'C:\Users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Logs\Terminations.txt' -Append

#Step 1: Disable the user object. *DONE*
$userEnabledStatus = (Get-aduser -Identity $username -properties *).Enabled
$userEnabledStatus
If ($userEnabledStatus = "true") {
    "$username is currently enabled. Disabling..."
    #set-aduser -identity $username -Enabled $false
    "$username is now disabled."
}
else {
    "$username is already disabled."
    }


#Step 2: Discover user's on-prem AD groups, log them, then remove them. *WIP*
    #Decide whether to 'wipe' all groups OR 'remove' target on-prem groups.
    #For logging/analytics, 'remove' might be best to keep track of exact groups.
$userGroups = (get-aduser -Identity $username -properties *).Memberof
"Generating groups list..."
"----------"
$userGroups

"----------"
foreach ($group in $userGroups) {}






#foreach ($group in $userGroups)
#{
#Write-Host $group
#sleep(1)
#}
#Step 3: Discover user's manager and delete from user object.
#$user = get-aduser -Identity daniel.landry -properties *
#$userManager = $user.manager
#$userManager
#Step 4: Discover user's "Date of Birth" and "Date of Hire" entries in extended attributes and remove them.
#Step 5: Move the user object to Disabled Users OU.
#Step 6: Block O365 sign-in.
#Step 7: Convert Exchange Mailbox to 'shared' from 'user'.
#Step 8: Revoke any licenses NOT inhereted by groups.