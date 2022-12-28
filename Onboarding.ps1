#Onboarding Script written by Daniel Landry

<#SUMMARY: Asks the engineer for onboarding information, creates the on-prem user object with the info given, assigns the desired on-prem groups, 
connects with AzureActiveDirectory to provision mailbox license and certain cloud access groups, then finally sends an email alert with an onboarding summary
to daniel.landry@sparkhound.com and a temp password notification email to HR@sparkhound.com#>

<#----------TO DO:
-BUILD:
--Access to mailbox folders (mine or dedicated) to push alerts/info via email to me.(12/17/22)
--LONGTERM: Script to read emails given to it, process targetted information to fulfill requests, and email back the results.
--For contractors, set 'Contract Labor' security group to being the primary group and remove old primary 'Domain Users'.

-FIX:
--Added commented-out code for fetching AAD's last directory sync time to consider implementing that information in some way with the 'waiting for AADSync' output statements for better monitoring.

-IMPROVE:
--Continue working on either improved user targetting instructions for $manager & $mirroruser sections.(12/17/22)
----------#>

<#----------Change Log:
+ Added small summary at the top to TLDR what the script does.
+ Corrected login sections to pull password from OneDrive file.
o Moved WIP manager verification code to end of script.
+ Reformatted the script to make it easier to read.
o This script might be moved into script 'LandryLabs.ps1' inside of a function to be called there.
----------#>

#Variable Declarations
#Step 1 - Information gathering.
"Please provide the following information for this onboarding:"
$Date = Get-Date
$FirstName = Read-Host "First Name"; 
$LastName = Read-Host "Last Name"; 
$Name = "$FirstName $LastName"; 
$Title = Read-Host "Title"; 
$Region = Read-Host "City"; 
$PhoneNumber = Read-Host "Phone Number";
$username = "$FirstName.$LastName"; 
$EmailAddress = "$username@sparkhound.com"; 
$PersonalEmail = Read-Host "Personal Email";
$Company = Read-Host "Company";
    if ($company -ne "Sparkhound") 
        {
            "Setting $username as a contractor"; 
            $Contractor = "Y"; 
            $Title = "Contractor ($company)"
        } 
    else 
        {
            $Contractor = "N"
        };
$Manager = Read-Host "Manager's username (First.Last)";
#WIP improvement code for manager and mirror user verification at end of script.
$MirrorUser = Read-Host "User to Mirror ('N' if not mirroring)"
$StartDate = Read-Host "Start Date"
$BusinessUnit = Read-Host "Business Unit"
$Department = Read-Host "Department";
$DepartmentConvert = "*$Department*"
$Practice = Read-Host "Practice";
$UserOUPath = "OU=$department,OU=$Practice,OU=Domain Users,DC=sparkhound,DC=com" 
$DepartmentLookup = (Get-ADOrganizationalUnit -Identity $UserOUPath) #Uses 'department' & 'practice' data to assist with locating the proper user OU to declare as the object path.
    if ($DepartmentLookup -ne "Null") 
        {
            "Department OU of $UserOUPath confirmed and assigned."
        }
$UKGSSO = Read-Host "UKG SSO Y/N"
$OpenAirSSO = Read-Host "OpenAir SSO Y/N"
$NetSuiteSSO = Read-Host "NetSuite SSO Y/N"
$PasswordFile = get-content -path "C:\Users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Pass2.txt"
$Password = ConvertTo-SecureString $PasswordFile -AsPlainText -Force
$ContractLabor = "CN=Contract Labor,OU=Contract Labor,OU=Sharepoint Groups,OU=Security Groups,DC=sparkhound,DC=com"

#Emailing info below
$From = "landrylabs.bot@sparkhound.com"; 
$To = "daniel.landry@sparkhound.com";
$Port = 587
$Subject = "[ONBOARDING] Task complete for $EmailAddress."
$SMTPserver = "smtp.office365.com"
$Cred = (get-credential -credential $from $PasswordLandryLabs)
$StepOneEmailNote = "FirstName: $Firstname`nLastName: $LastName`nFullName: $Name`nTitle: $Title`nRegion: $Region`nPhoneNumber: $PhoneNumber`nUsername: $username`nEmailAddress: $EmailAddress`nPersonalEmail: $PersonalEmail`nCompany: $Company`nManager: $Manager`nMirrorUser: $MirrorUser`nStartDate: $StartDate`nBusinessUnit: $BusinessUnit`nDepartment: $Department`nPractice: $Practice`nAssigned OU Path: $UserOUPath`nUKG: $UKGSSO`nOpenAir: $OpenAirSSO`nNetSuite: $NetSuiteSSO`nPassword: Welcome@123`n"



#Establishing AzureAD Connection for cloud items.
"Establishing AzureAD Connection for cloud items..."
$adminUser = "dalandry.admin@sparkhound.com"
#$AdminPass = ConvertTo-SecureString -String "Spike@admin2" -AsPlainText -Force
$AdminPassFile = Get-content -Path "C:\Users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Pass1.txt"
$AdminPass = ConvertTo-SecureString $AdminPassFile -AsPlainText -Force
$AdminCred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $adminUser, $AdminPass

Connect-AzureAD -Credential $AdminCred
#Connect-ExchangeOnline #Will use ExchangeOnline for sending mail alerts.



#Step 2: Create user object
"Step 2 - Starting account creation..."
New-ADUser -Name "$Name" -samaccountname $username -UserPrincipalName $EmailAddress -AccountPassword $Password -Enabled $true -ChangePasswordAtLogon $true -GivenName $FirstName -Surname $LastName -DisplayName $Name -City $Region -Company $Company -Department $Department -Description $Title -EmailAddress $EmailAddress -Manager $Manager -MobilePhone $PhoneNumber -Title $Titlex -OfficePhone $PhoneNumber
$CheckAccountCreation = (get-aduser -Identity $username -properties *).userprincipalname
    if ($CheckAccountCreation -eq $EmailAddress) 
        {"Account created for $Name. Populating information..."} else 
        {"Account not created. Please investigate."}
"Finished populating information."



#Step 3: Mirror security groups from target user
"Step 3 - Starting on-prem security group mirroring..."
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
    Else
        {
            "No groups are requested to be mirrored."
        }


#Move new user object to department OU to allow AADSyncing.
"Step 4 of X - Moving $username to designated OU for $Department to allow AADSync."
$UserPath = (get-aduser -identity $username -properties *).distinguishedname
move-adobject -identity $UserPath -targetpath $UserOUPath


#Still need to work on auto switching primary group for contractors so that 'domain users' can be auto deleted.
    if ($Contractor -eq "Y")
        {
            "Adding contractor $username to Contract Labor security group..."
            Add-ADGroupMember $ContractLabor $username
        }
    else {"Not a contractor...Skipping contract labor group."}

#Step 3: Add user to applicable cloud groups (O365 license, Ultipro, netsuite, openair)
    ##Confirms detection of new user object being synced to cloud AD.
    ##If unable to locate user, wait 60 and scan again. Once found, proceed with adding the groups.
    do
        {
            "Waiting for $username to sync to AzureAD to proceed."
            #Add "(Get-AzureADTenantDetail).companylastdirsynctime" timestamp into waiting output.
            $NewUserCLoudSynced = (get-azureaduser -filter "userprincipalname eq '$EmailAddress'").userprincipalname
            sleep 60
        }
    Until ($NewUserCloudSynced -eq "$EmailAddress")

"$username detected in AzureAD."
"Step 5 - Joining $username to 'Microsoft 365 Business Premium (Cloud Group)' for mailbox access."
    ##Add new user to Business Premium license group.
$MailboxGroup = (get-azureadgroup -SearchString "sg.microsoft 365 Business Premium (Cloud Group)").objectid
$NewUserObjectID = (get-azureaduser -filter "userprincipalname eq '$EmailAddress'").objectid
Add-AzureADGroupMember -objectid "$MailboxGroup" -RefObjectId "$NewUserObjectID"; 
$License = "sg.microsoft 365 Business Premium (Cloud Group)";

##Add new user to UKG SSO group.
    If ($UKGSSO -eq "Y")
        {
            "Step 5.2 - Joining $username to 'UKG' group..."
            $MailboxGroup = (get-azureadgroup -SearchString "UltiPro_Users").objectid
            $NewUserObjectID = (get-azureaduser -filter "userprincipalname eq '$EmailAddress'").objectid
            Add-AzureADGroupMember -objectid "$MailboxGroup" -RefObjectId "$NewUserObjectID"; 
            $UKG = "UltiPro_Users"
        }
    Else 
        {
            "UKG not requested..."
        }

##Add new user to OpenAir SSO group.
    If ($OpenAirSSO -eq "Y")
        {
            "Step 5.3 - Joining $username to 'OpenAir' group..."
            $MailboxGroup = (get-azureadgroup -SearchString "OpenAir_Users_Prod").objectid
            $NewUserObjectID = (get-azureaduser -filter "userprincipalname eq '$EmailAddress'").objectid
            Add-AzureADGroupMember -objectid "$MailboxGroup" -RefObjectId "$NewUserObjectID"; 
            $OpenAir = "OpenAir_Users_Prod"
        }
    Else 
        {
            "OpenAir not requested..."
        }

##Add new user to NetSuite SSO group.
    If ($NetSuiteSSO -eq "Y")
        {
            "Step 5.4 - Joining $username to 'NetSuite' group..."
            $MailboxGroup = (get-azureadgroup -SearchString "NetSuiteERP_Users").objectid
            $NewUserObjectID = (get-azureaduser -filter "userprincipalname eq '$EmailAddress'").objectid
            Add-AzureADGroupMember -objectid "$MailboxGroup" -RefObjectId "$NewUserObjectID"; 
            $Netsuite = "NetSuiteERP_Users"
        }
    Else 
        {
            "NetSuite not requested..."
        }


<## Preset variables to perform email test. Will isolate into dedicated script later.
"TEST"
$Firstname = "Dan"
$LastName = "Doe"
$username = "$FirstName.$LastName"
$EmailAddress = "$username@sparkhound.com"
$MirrorUser = "Daniel.Landry"
$License = "Email license"
$UKG = "UKG"
$OpenAir = "OA"
$Netsuite = "NET"
$UserOUPath = "user\ou\path"
#>

#Mailing info below
$LandryLabsBotPassFile = get-content -path "C:\users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Pass3.txt"
$PasswordLandryLabs = ConvertTo-SecureString $LandryLabsBotPassFile -AsPlainText -Force
$From = "landrylabs.bot@sparkhound.com";
$To = "daniel.landry@sparkhound.com";
$Port = 587
$Subject = "[ONBOARDING] Task complete for $EmailAddress."
$SMTPserver = "smtp.office365.com"
$Cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $from, $PasswordLandryLabs
$Signature = "`n`nThank you,`nLandryLabs Bot`nTask Assistant"
$NameforNote = "$FirstName_$LastName"
$OnboadingFileName = "Onboarding_Task_Complete_for_$NameforNote"

#Begins technician note for CWM ticket/HR.
$CWMnote = "$Date`n"
$CWMnote = ($CWMnote + "Step 6 of X - Generated note for ConnectwiseManage ticket below`n")
$CWMnote = ($CWMnote + "====================`n")
$CWMnote = ($CWMnote + "Hello HR,`n");
$CWMnote = ($CWMnote + "$EmailAddress account has been created for $Name.`n");
$CWMnote = ($CWMnote + "Initial password emailed to HR.`n");
if ($MirrorUser -ne "N")
    {
        $CWMnote = ($CWMnote + "Mirrored security groups from $MirrorUser`n");
    } 
else 
    {
        $CWMnote = ($CWMnote + "No user assigned to mirror security groups.`n");
    }
$CWMnote = ($CWMnote + "Assigned cloud groups: $License, $UKG, $OpenAir, $Netsuite.`n");
$CWMnote = ($CWMnote + "Assigned to OU: $UserOUPath`n");
$CWMnote = ($CWMnote + "====================`n");
$CWMnote | Out-File -FilePath C:\Users\daniel.landry\Desktop\Onboarding_Logs.txt -Append
$CWMnote | Out-File -FilePath "C:\Users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Logs\Onboarding_Logs.txt" -Append
Send-MailMessage -from $From -To $To -Subject $Subject -Body "$StepOneEmailNote`n$CWMnote`n$signature" -SmtpServer $SMTPserver -Credential $Cred -Verbose -UseSsl -Port $Port


#Separate email alert pushed to HR@sparkhound.com
#$ToHR = "HR@sparkhound.com";
$ToHR = "daniel.landry@sparkhound.com";
$BodyHR = "Hello Hr,`n`n$EmailAddress has been created for $Name. Forwarding their initial password of 'Welcome@123'."
Send-MailMessage -from $From -To $ToHR -Subject $Subject -Body $BodyHR`n$signature -SmtpServer $SMTPserver -Credential $Cred -Verbose -UseSsl -Port $Port


<#----------(Improved manager search 'dynamic list to make choice' - WIP)
#Improved manager code to treat the input of $manager as a user object search request.
#Takes $manager value and queries AD for all user objects that contain the string.
#Pushes that new array of users out as a dynamically numbered list and asks for the right user to be selected.
#(WIP) Allow the user input to select the appropriate user in the list and assign that selected user to the #manager function.


do {$ManagerRequest = Read-Host "Manager's username (First.Last)";
$ManagerRequestConvert = "*$ManagerRequest*"
$ManagerVerification = (Get-ADUser -filter {samaccountname -like $ManagerRequestConvert}).samaccountname; 
"Searching for user..."
"The following match your request..."
$qty = 1; foreach ($ManagerRequestResult in $ManagerVerification) 
{"$qty) $ManagerRequestResult"; ++$qty; $ManagerOption = $}
$ManOpt
$ManOptSelected = Read-Host "Please select the number for your choice"; $Manager = "$ManOpt.$ManOptSelected"; $Manager}
----------#>

<#----------(Improved manager search 'Return one user in array and ask for each' - WIP)
do 
{$ManagerRequest = Read-Host "Manager's username (First.Last)";
    $ManagerRequestConvert = "*$ManagerRequest*"
    $ManagerVerification = (Get-ADUser -filter {samaccountname -like $ManagerRequestConvert}).samaccountname; 
    "Searching for user..."
    "The following match your request..."
    $qty = 1; 
    do 
        {foreach ($ManagerRequestResult in $ManagerVerification) 
            {"$qty) $ManagerRequestResult"; ++$qty; $ManagerChoice = Read-Host "Confirm $ManagerRequestResult to be the manager? Enter Y/N"
                if ($ManagerChoice -eq "N") {} 
                elseif ($ManagerChoice -eq "Y") 
                {$Manager = $ManagerRequestResult; "$ManagerRequestResult set as manager."} 
                else {"Invalid option. Manager not declared."}
            }
        }
until 
    ($Manager -ne "null")} 
    while 
        (while ($Manager -eq "null"))
$Manager
----------#>
