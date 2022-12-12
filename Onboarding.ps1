#"Onboarding Script"

#Variable Declarations
$FirstName = Read-Host "First Name"
$LastName = Read-Host "Last Name"
$FullName = "$FirstName.$LastName"
$PhoneNumber = Read-Host "Phone Number"
$PersonalEmail = Read-Host "Personal Email"
$StartDate = Read-Host "Start Date"
$Region = Read-Host "Region"
$Practice = Read-Host "Practice"
$Department = Read-Host "Department"
$Manager = Read-Host "Manager"
$Title = Read-Host "Title"
$EmploymentStatus = Read-Host "Full time/Part time/Contractor"
$BusinessUnit = Read-Host "Business Unit"
$MirrorUser = Read-Host "User to Mirror"
$UKGSSO = Read-Host "UKG SSO Y/N"
$OpenAirSSO = Read-Host "OpenAir SSO Y/N"
$NetSuiteSSO = Read-Host "NetSuite SSO Y/N"
$TempPassword = "Welcome@123"


#Step 1: Create user object
    #Will use 'new-aduser' to create the object with name only THEN add info with 'set-aduser'.
New-ADUser -SamAccountName "$FullName"

#-GivenName "$FirstName" -Surname "$LastName" -DisplayName "$FirstName $LastName" -path '?' -AccountPassword (-AsSecureString "$TempPassword") -City "$Region" -Company "Sparkhound" -Department "$Department" -Description


$NewUser = "DanLand.User"
#Step ?: mirror security groups from target user
$MirrorUser = Read-Host "Mirror user: ". #Request the user that will be mirrored
$MirrorGroups = (get-aduser -Identity $MirrorUser -properties *).Memberof #Fetches that user's on-prem groups
$MirrorFunction = foreach ($MirrorGroupEntry in $MirrorGroups) 
{
    "Adding $NewUser to $MirrorGroupEntry"
    Add-ADGroupMember $MirrorGroupEntry $NewUser
}
$PostMirrorNewUserGroups = (get-aduser -Identity $NewUser -properties *).Memberof
$MirrorFunction
if ($PostMirrorNewUserGroups = $MirrorUser)
{
    "------------------------------"
    "All groups have been successfully mirrored from $MirrorUser."
}
else
{
    "The mirroring was not successful."
}