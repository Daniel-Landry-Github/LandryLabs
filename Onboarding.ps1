#"Onboarding Script"

#Variable Declarations
$FirstName = Read-Host "First Name"
$LastName = Read-Host "Last Name"
$FullName = "$FirstName $LastName"
$Title = Read-Host "Title"
$Region = Read-Host "Region"
$PhoneNumber = Read-Host "Phone Number"
$username = "$FirstName.$LastName"
$EmailAddress = "$username@sparkhound.com"
$PersonalEmail = Read-Host "Personal Email"
$Department = Read-Host "Department"
$Company = "Sparkhound"
$Manager = Read-Host "Manager"
$MirrorUser = Read-Host "User to Mirror (N if no mirroring)"
$Contractor = Read-Host "Contractor Y/N" 
#Contractor changes: Descrption 'contractor (company)', job title 'Contractor', Company 'Contractor', AD Primary group 'Contract Labor'.
if ($contractor -eq "Y")
{
$Company = Read-Host "Contractor Company"
$Title = "Contractor ($company)"
}
else {""}

$StartDate = Read-Host "Start Date"
$Practice = Read-Host "Practice"
$EmploymentStatus = Read-Host "Full time/Part time/Contractor"
$BusinessUnit = Read-Host "Business Unit"

$UKGSSO = Read-Host "UKG SSO Y/N"
$OpenAirSSO = Read-Host "OpenAir SSO Y/N"
$NetSuiteSSO = Read-Host "NetSuite SSO Y/N"
$Password = Read-Host "Password: " -AsSecureString
$AdminCredUser = Get-Credential -UserName dalandry.admin@sparkhound.com

#Establishing MSOline Connection for cloud items.
Connect-MsolService
Connect-AzureAD



#Step 1: Create user object
    #Will use 'new-aduser' to create the object with name only THEN add info with 'set-aduser'.
New-ADUser -Name "$FullName" -samaccountname $username -AccountPassword $Password -Enabled:$true -GivenName $FirstName -Surname $LastName -DisplayName $FullName -City $Region -Company $Company -Department $Department -Description $Title -EmailAddress $EmailAddress -Manager $Manager -MobilePhone $PhoneNumber -Title $Title



#Step 2: Mirror security groups from target user
#$MirrorUser = Read-Host "Mirror User" #Used for isolated group adding requests.
#$Username = Read-Host "New User" #Used for isolated group adding requests.
if ($MirrorUser -ne "N")
{
$MirrorGroups = (get-aduser -Identity $MirrorUser -properties *).Memberof #Fetches that user's on-prem groups
$MirrorFunction = foreach ($MirrorGroupEntry in $MirrorGroups) 
{
    "Adding $username to $MirrorGroupEntry"
    Add-ADGroupMember $MirrorGroupEntry $username
}
$PostMirrorNewUserGroups = (get-aduser -Identity $username -properties *).Memberof
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
}
Else{"No groups will be mirrored..."}


#Still need to work on auto switching primary group for contractors so that 'domain users' can be auto deleted.
if ($Contractor -eq "Y")
{
Add-ADGroupMember "CN=Contract Labor,OU=Contract Labor,OU=Sharepoint Groups,OU=Security Groups,DC=sparkhound,DC=com" $username
}
else {"Skipping contract labor group."}

#Step 3: Add user to applicable cloud groups (O365 license, Ultipro, netsuite, openair)
    ##Confirms detection of new user object being synced to cloud AD.
    ##If unable to locate user, wait 60 and scan again. Once found, proceed with adding the groups.
do
{
"Waiting for $username to sync to cloud to proceed."
$NewUserCLoudSynced = get-azureaduser -filter "userprincipalname eq '$EmailAddress'"
sleep 60
}
Until ($NewUserCloudSynced -eq "$EmailAddress")

    ##Add new user to Business Premium license group.
$MailboxGroup = (get-azureadgroup -SearchString "sg.microsoft 365 Business Premium (Cloud Group)").objectid
$NewUserObjectID = (get-azureaduser -filter "userprincipalname eq '$EmailAddress'").objectid
Add-AzureADGroupMember -objectid "$MailboxGroup" -RefObjectId "$NewUserObjectID"

    ##Add new user to UKG SSO group.
If ($UKGSSO = Y)
{
"Adding user to UKG SSO group"
$MailboxGroup = (get-azureadgroup -SearchString "UltiPro_Users").objectid
$NewUserObjectID = (get-azureaduser -filter "userprincipalname eq '$EmailAddress'").objectid
Add-AzureADGroupMember -objectid "$MailboxGroup" -RefObjectId "$NewUserObjectID"}
Else {"UKG not requested..."}

    ##Add new user to OpenAir SSO group.
If ($OpenAirSSO = Y)
{
"Adding user to UKG SSO group"
$MailboxGroup = (get-azureadgroup -SearchString "OpenAir_Users_Prod").objectid
$NewUserObjectID = (get-azureaduser -filter "userprincipalname eq '$EmailAddress'").objectid
Add-AzureADGroupMember -objectid "$MailboxGroup" -RefObjectId "$NewUserObjectID"}
Else {"OpenAir not requested..."}

    ##Add new user to NetSuite SSO group.
If ($NetSuiteSSO = Y)
{
"Adding user to UKG SSO group"
$MailboxGroup = (get-azureadgroup -SearchString "NetSuiteERP_Users").objectid
$NewUserObjectID = (get-azureaduser -filter "userprincipalname eq '$EmailAddress'").objectid
Add-AzureADGroupMember -objectid "$MailboxGroup" -RefObjectId "$NewUserObjectID"}
Else {"NetSuite not requested..."}