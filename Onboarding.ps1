#"Onboarding Script"

#Variable Declarations
$FirstName = Read-Host "First Name"; $LastName = Read-Host "Last Name"; $Name = "$FirstName $LastName"; $Title = Read-Host "Title"; $Region = Read-Host "Region"; $PhoneNumber = Read-Host "Phone Number";
$username = "$FirstName.$LastName"; $EmailAddress = "$username@sparkhound.com"; $PersonalEmail = Read-Host "Personal Email"; $Department = Read-Host "Department"; $Company = "Sparkhound"; $Manager = Read-Host "Manager";
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
#$AdminCredUser = Get-Credential -UserName dalandry.admin@sparkhound.com -Message "Enter your admin password: "

#Establishing AzureAD Connection for cloud items.
"Establishing AzureAD Connection for cloud items..."
Connect-AzureAD #-Credential $AdminCredUser



#Step 1: Create user object

"Step 1 of X - Starting account creation..."
New-ADUser -Name "$Name" -samaccountname $username -UserPrincipalName $EmailAddress -AccountPassword $Password -Enabled $true -ChangePasswordAtLogon $true -GivenName $FirstName -Surname $LastName -DisplayName $Name -City $Region -Company $Company -Department $Department -Description $Title -EmailAddress $EmailAddress -Manager $Manager -MobilePhone $PhoneNumber -Title $Titlex -OfficePhone $PhoneNumber
$CheckAccountCreation = (get-aduser -Identity $username -properties *).userprincipalname
if ($CheckAccountCreation -eq $EmailAddress) {"Account created for $Name. Populating information..."} else {"Account not created. Please investigate."}
"Finished populating information."



#Step 2: Mirror security groups from target user
"Step 2 of X - Starting on-prem security group mirroring..."
if ($MirrorUser -ne "N")
{
"$name will mirror the security groups of $MirrorUser."
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
Else{"No groups are requested to be mirrored."}


#Still need to work on auto switching primary group for contractors so that 'domain users' can be auto deleted.
if ($Contractor -eq "Y")
{
"Adding contractor $username to Contract Labor security group..."
Add-ADGroupMember "CN=Contract Labor,OU=Contract Labor,OU=Sharepoint Groups,OU=Security Groups,DC=sparkhound,DC=com" -member $username
}
else {"Skipping contract labor group."}

#Step 3: Add user to applicable cloud groups (O365 license, Ultipro, netsuite, openair)
    ##Confirms detection of new user object being synced to cloud AD.
    ##If unable to locate user, wait 60 and scan again. Once found, proceed with adding the groups.
do
{
"Waiting for $username to sync to AzureAD to proceed."
$NewUserCLoudSynced = (get-azureaduser -filter "userprincipalname eq '$EmailAddress'").userprincipalname
sleep 60
}
Until ($NewUserCloudSynced -eq "$EmailAddress")

"$username detected in AzureAD."
"Joining $username to 'Microsoft 365 Business Premium (Cloud Group)'"
    ##Add new user to Business Premium license group.
$MailboxGroup = (get-azureadgroup -SearchString "sg.microsoft 365 Business Premium (Cloud Group)").objectid
$NewUserObjectID = (get-azureaduser -filter "userprincipalname eq '$EmailAddress'").objectid
Add-AzureADGroupMember -objectid "$MailboxGroup" -RefObjectId "$NewUserObjectID"

    ##Add new user to UKG SSO group.
If ($UKGSSO -eq "Y")
{
"Joining $username to 'UKG' group..."
$MailboxGroup = (get-azureadgroup -SearchString "UltiPro_Users").objectid
$NewUserObjectID = (get-azureaduser -filter "userprincipalname eq '$EmailAddress'").objectid
Add-AzureADGroupMember -objectid "$MailboxGroup" -RefObjectId "$NewUserObjectID"}
Else {"UKG not requested..."}

    ##Add new user to OpenAir SSO group.
If ($OpenAirSSO -eq "Y")
{
"Joining $username to 'OpenAir' group..."
$MailboxGroup = (get-azureadgroup -SearchString "OpenAir_Users_Prod").objectid
$NewUserObjectID = (get-azureaduser -filter "userprincipalname eq '$EmailAddress'").objectid
Add-AzureADGroupMember -objectid "$MailboxGroup" -RefObjectId "$NewUserObjectID"}
Else {"OpenAir not requested..."}

    ##Add new user to NetSuite SSO group.
If ($NetSuiteSSO -eq "Y")
{
"Joining $username to 'NetSuite' group..."
$MailboxGroup = (get-azureadgroup -SearchString "NetSuiteERP_Users").objectid
$NewUserObjectID = (get-azureaduser -filter "userprincipalname eq '$EmailAddress'").objectid
Add-AzureADGroupMember -objectid "$MailboxGroup" -RefObjectId "$NewUserObjectID"}
Else {"NetSuite not requested..."}