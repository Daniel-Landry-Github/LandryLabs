#Add user to applicable cloud groups (O365 license, Ultipro, netsuite, openair)
    ##Confirms detection of new user object being synced to cloud AD.
    ##If unable to locate user, wait 60 and scan again. Once found, proceed with adding the groups.


$username = Read-Host "Username:"
$EmailAddress = "$username@sparkhound.com"
$UKGSSO = Read-Host "UKG SSO - Y/N:"
$OpenAirSSO = Read-Host "OpenAirSSO - Y/N:"
$NetSuiteSSO = Read-Host "NetSuiteSSO - Y/N:"
#$AdminCred = Get-Credential -UserName "dalandry.admin@sparkhound.com" -Message "Enter admin password"

Connect-AzureAD #-Credential $AdminCred
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