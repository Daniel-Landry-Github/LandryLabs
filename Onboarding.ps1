#"Onboarding Script"

#Variable Declarations
$FirstName = Read-Host "First Name"
$LastName = Read-Host "Last Name"
$FullName = "$FirstName $LastName"
$Title = Read-Host "Title"
$Region = Read-Host "Region"
$PhoneNumber = Read-Host "Phone Number"
$EmailAddress = "$FullName@sparkhound.com"
$PersonalEmail = Read-Host "Personal Email"
$Department = Read-Host "Department"
$Company = "Sparkhound"
$Manager = Read-Host "Manager"
$MirrorUser = Read-Host "User to Mirror"

$StartDate = Read-Host "Start Date"
$Practice = Read-Host "Practice"
$EmploymentStatus = Read-Host "Full time/Part time/Contractor"
$BusinessUnit = Read-Host "Business Unit"

$UKGSSO = Read-Host "UKG SSO Y/N"
$OpenAirSSO = Read-Host "OpenAir SSO Y/N"
$NetSuiteSSO = Read-Host "NetSuite SSO Y/N"
$Password = Read-Host -AsSecureString

#Establishing MSOline Connection for cloud items.
#Connect-MsolService



#Step 1: Create user object
    #Will use 'new-aduser' to create the object with name only THEN add info with 'set-aduser'.
New-ADUser -Name "$FullName" -AccountPassword $Password -Enabled:$true -GivenName $FirstName -Surname $LastName -DisplayName $FullName -City $Region -Company $Company -Department $Department -Description $Title -EmailAddress $EmailAddress -Manager $Manager -MobilePhone $PhoneNumber -Title $Title
#Set-ADUser -identity "$Firstname.$LastName" -GivenName "$FirstName" -Surname "$LastName" -DisplayName "$FirstName $LastName" -City "$Region" 
#Set-ADUser -Company "Sparkhound" -Department "$Department" -Description $Title -EmailAddress "$EmailAddress" -Enabled:$true -Manager "$Manager" -MobilePhone "$PhoneNumber"


#Step 2: Mirror security groups from target user
#$MirrorUser = Read-Host "Mirror User" #Used for isolated group adding requests.
#$NewUser = Read-Host "New User" #Used for isolated group adding requests.
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
#Step 3: Add user to applicable cloud groups (O365 license, Ultipro, netsuite, openair)
