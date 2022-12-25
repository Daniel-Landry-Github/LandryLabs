#Detect emails sent to Landrylabs.bot@sparkhound.com (bonus if detects which folder it delivers to) and processes it based on certain subject keywords.

#For now, best initial approach to start the task might be to send onboarding emails to the LandryLabs\tasks folder to be processed.
#For tasks that do not require much info (maybe terminations), Landrylabs.bot can still scan exchance message trace once every minute to process keywords in subject lines to start tasks.

<#----------Change Log:
+ Created baseline script to test.
----------#>

$adminUser = "dalandry.admin@sparkhound.com"

$AdminPassFile = Get-content -Path "C:\Users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\Pass1.txt"
$AdminPass = ConvertTo-SecureString $AdminPassFile -AsPlainText -ForceConnect-ExchangeOnline -Credential $AdminCred
get-messagetrace -recipientaddress "landrylabs.bot@sparkhound.com" | ft Received, SenderAddress, Subject -AutoSize| out-file 'C:\users\daniel.landry\OneDrive - Sparkhound Inc\LandryLabs\logs\Email_Monitoring.txt' -append



#get-messagetrace -recipientaddress "landrylabs.bot@sparkhound.com" | ft Received, SenderAddress, Subject
#>
<#
$LoopStop = 1
$DateMonth = get-date -UFormat "%m"
$DateDay = get-date -UFormat "%d"
$DateYear = get-date -UFormat "%Y"
$DateTime = get-date -UFormat "%R"
$DateZoneOffset = get-date -UFormat %Z
$StartTime = "$DateMonth/$DateDay/$DateYear $DateTime"
$StartTime
Sleep 120
$DateMonth = get-date -UFormat "%m"
$DateDay = get-date -UFormat "%d"
$DateYear = get-date -UFormat "%Y"
$DateTime = get-date -UFormat "%R"
$EndTime = "$DateMonth/$DateDay/$DateYear $DateTime"
$EndTime
While ($LoopStop -ne 999)
{
"start time: $StartTime"
"end time: $EndTime"
#Do the trace with those times...
"Starting trace..."
$StartTime = $EndTime
Sleep 120
$DateMonth = get-date -UFormat "%m"
$DateDay = get-date -UFormat "%d"
$DateYear = get-date -UFormat "%Y"
$DateTime = get-date -UFormat "%R"
$EndTime = "$DateMonth/$DateDay/$DateYear $DateTime"
$LoopStop = $LoopStop++
$LoopStop
}
#>