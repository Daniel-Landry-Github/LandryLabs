<# (3/2/23) Consider best ways to automate computer healthchecks for spare/returned computers to keep a better eye on our hardware's conditions.
--Pull 'SystemInfo' information about machine.
--Run Battery Check 'powercfg /batteryreport /output "C:\battery-report.html"
--Pull OS license activiation information
--Run CHKDSK.

RUN IN STAGES:
    STAGE 1 - FETCH INFORMATION
    STAGE 2 - PERFORM CHECKS AGAINST STANDARDIZED VALUES FOR CERTAIN ITEMS FOR STAGE 3 TO ATTEMPT TO CORRECT THEM.
    STAGE 3 - RUN TASKS TO UPDATE EACH FLAGGED ITEM TO MIRROR THE STANDARD WE HAVE ESTABLISHED.
        - CONSIDER IMPLEMENTING A PROGRESS LOG TEXT FILE THAT CAN BE SCANNED TO RE-ROUTE THE SCRIPT WHERE NEEDED IN THE CASE OF RESTARTS)
    STAGE 4 - VERIFY SUCCESS/FAILURE OF UPDATED FLAGGED ITEMS.
    STAGE 5 - RECORD AND DISTINGUISH ITEMS THAT WERE STANDARD AND UPDATED IN EMAIL PUSH.
#>

$pwd = pwd
$hostname = hostname
$LaptopCheck = "N"
#Fetch Machine/System Info
$systeminfofile = "$pwd\SystemInfoLog-$hostname.txt"
systeminfo.exe | Out-File -FilePath $systeminfofile
    #Host Name, OS Name, OS Version, Original Intall Date, System Model, 

#InfoDump1
$InfoDump1file = "$pwd\InfoDump1Log-$hostname.txt"
Get-CimInstance -classname win32_operatingsystem | select * | Out-File -FilePath $InfoDump1file

#Run CHKDSK and output results to text file.
$chkdskfile = "$pwd\CHKDSK-Log-$hostname.txt"
#chkdsk.exe | Out-File -FilePath $chkdskfile

#Additional fetchable pages to inspect.
$HealthCheckFile = "$pwd\HEALTHCHECK-$hostname.txt"
<# "WIN32_COMPUTERSYSTEM" | out-file -FilePath $Additionalinfofile
Get-CimInstance -ClassName Win32_ComputerSystem | fl *| out-file -FilePath $Additionalinfofile
    #Domain, Model, Name, TotalPhysicalMemory(!), PartOfDomain(!), Status(!).
"WIN32_BIOS" | out-file -FilePath $Additionalinfofile
Get-CimInstance -ClassName Win32_BIOS | fl *| out-file -FilePath $Additionalinfofile
    #Serial, Version, Status.
"WIN32_PROCESSOR" | out-file -FilePath $Additionalinfofile
Get-CimInstance -ClassName Win32_processor | fl *| out-file -FilePath $Additionalinfofile
    #Name, Status, .
"GET-PHYSICALDISK" | out-file -FilePath $Additionalinfofile
get-physicaldisk | fl *| out-file -FilePath $Additionalinfofile 
Get-CimInstance -ClassName Win32_usbhub | fl *
    #Description, Status.
#>

#TEST SPECIFIC INFO ABOUT COMPUTER
$pwd = pwd
$hostname = hostname
#OPERATING SYSTEM
$OSEdition = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    #STAGE 2 - STANDARD: 'Microsoft Windows 10 Enterprise'
    #STAGE 3 - TASK: UPDATE PRODUCT KEY TO THE PROVIDED W10 ENTERPRISE.
    #STAGE 4 - CONFIRM NEW WINDOWS EDITION.
$OSVersion = (Get-CimInstance -ClassName Win32_OperatingSystem).Version
    #STAGE 2 - STAMDARD: '21H2'
    #STAGE 3 - PULL WINDOWS UPDATES TO REACH STANDARD. (RESTART MACHINE AND RECHECK/RE-REQUEST UPDATES AS NEEDED)
$OSOrganization = (Get-CimInstance -ClassName Win32_OperatingSystem).Organization
$OSRegisteredUser = (Get-CimInstance -ClassName Win32_OperatingSystem).RegisteredUser
$OSSerialNumber = (Get-CimInstance -ClassName Win32_OperatingSystem).SerialNumber
$InstallDate = (Get-CimInstance -ClassName Win32_OperatingSystem).InstallDate
$CSUserName = (Get-CimInstance -ClassName Win32_ComputerSystem).UserName
$LastBootUpTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
$CSDomain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain
#HARDWARE-CPU
$CSModel = (Get-CimInstance -ClassName Win32_ComputerSystem).Model
$CSSystemSKUNumber = (Get-CimInstance -ClassName Win32_ComputerSystem).SystemSKUNumber
$CPUName = (Get-CimInstance -ClassName Win32_Processor).Name
$CPUPhysicalCores = (Get-CimInstance -ClassName Win32_Processor).NumberOfCores
$CPULogicalProcessors = (Get-CimInstance -ClassName Win32_Processor).NumberOfLogicalProcessors
$CSTotalPhysicalMemory = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory
#HARDWARE-STORAGE
$DISKMediaType = (get-physicaldisk).MediaType
$DISKHealthStatus = (get-physicaldisk).HealthStatus
$DISKSize = (get-physicaldisk).Size
#HARDWARE-MEMORY
$MEMDescription = (Get-CimInstance -ClassName Win32_PhysicalMemory).Description
$MEMManufacturer = (Get-CimInstance -ClassName Win32_PhysicalMemory).Manufacturer
$MEMCapacity = (Get-CimInstance -ClassName Win32_PhysicalMemory).Capacity

$healthcheckarray = @(
        "HEALTH CHECK ($hostname):`n",
        "=====OPERATING SYSTEM=====`n", 
        "OS Edition: $OSEdition`n",
        "OS Version: $OSVersion`n",
        "OS Organization: $OSOrganization`n",
        "OS Registered User: $OSRegisteredUser`n",
        "OS Serial Number: $OSSerialNumber`n",
        "Install Date: $InstallDate`n",
        "Username: $CSUserName`n",
        "Last Boot Up Time: $LastBootUpTime`n",
        "Domain: $CSDomain`n", #0(Standalone Workstation), 1(Member Workstation), 2(Standalone Server), 3(Member Server), 4(Backup Domain Controller), 5(Primary Domain Controller).
        "`n=====HARDWARE=====`n",
        "<<CPU>>`n",
        "Machine Model: $CSModel`n",
        "System SKU Number: $CSSystemSKUNumber`n",
        "Processor: $CPUName`n",
        "Physcial Cores: $CPUPhysicalCores`n",
        "Logical Cores: $CPULogicalProcessors`n",
        "Physical Memory: $CSTotalPhysicalMemory`n",
        "<<STORAGE>>`n",
        "Media Type: $DISKMediaType`n",
        "Health Status: $DISKHealthStatus`n",
        "Size: $DISKSize`n",
        "<<MEMORY>>`n",
        "Description: $MEMDescription`n",
        "Manufacturer: $MEMManufacturer`n",
        "Capacity: $MEMCapacity`n"
                    )

#HARDWARE-BATTERY (CHECKS IF APPLICABLE)
$CSModelArray = @(($CSModel.Split(" ")))
foreach ($item in $CSModelArray)
    {
        $itemstring = "$item"
        $Zbook = "ZBook";
        $Latitude = "Latitude";
        $Precision = "Precision";
        if ($itemstring -eq $Zbook -or $itemstring -eq $Latitude -or $itemstring -eq $Precision)
            {
                $LaptopCheck = "Y"
                $BATTName = (Get-CimInstance -ClassName Win32_battery).Name
                $BATTDescription = (Get-CimInstance -ClassName Win32_battery).Description
                $BATTStatus = (Get-CimInstance -ClassName Win32_battery).Status

                #BatteryReport
                $BatteryReportfile = "$pwd\BatteryReport-$hostname.html"
                powercfg /batteryreport /output $BatteryReportfile

                $healthcheckarray += "<<BATTERY>>`n"
                $healthcheckarray += "Name: $BATTName`n"
                $healthcheckarray += "Description: $BATTDescription`n"
                $healthcheckarray += "Status: $BATTStatus`n"
            }
    }
$healthcheckarrayfile = "$pwd\HEALTHCHECK-$hostname.txt"
$healthcheckarray | Out-File -FilePath $healthcheckarrayfile


<# "=====OPERATING SYSTEM====="
"OS Edition: $OSEdition"
"OS Version: $OSVersion"
"OS Organization: $OSOrganization"
"OS Registered User: $OSRegisteredUser"
"OS Serial Number: $OSSerialNumber"
"Install Date: $InstallDate"
"Username: $CSUserName"
"Last Boot Up Time: $LastBootUpTime"
"Domain: $CSDomain" #0(Standalone Workstation), 1(Member Workstation), 2(Standalone Server), 3(Member Server), 4(Backup Domain Controller), 5(Primary Domain Controller).

"`n=====HARDWARE=====`n"
"<<CPU>>"
"Machine Model: $CSModel"
"System SKU Number: $CSSystemSKUNumber"
"Processor: $CPUName"
"Physcial Cores: $CPUPhysicalCores"
"Logical Cores: $CPULogicalProcessors"
"Physical Memory: $CSTotalPhysicalMemory"
"<<STORAGE>>"
"Media Type: $DISKMediaType"
"Health Status: $DISKHealthStatus"
"Size: $DISKSize"
"<<MEMORY>>"
"Description: $MEMDescription"
"Manufacturer: $MEMManufacturer"
"Capacity: $MEMCapacity"
"<<BATTERY>>"
"Name: $BATTName"
"Description: $BATTDescription"
"Status: $BATTStatus" #>





#Compress info files into archive file.

#Create array of attachment files.
if ($LaptopCheck -eq "N")
    {
        $AttachmentArray = @($systeminfofile, $InfoDump1file, $healthcheckarrayfile)
    }
elseif ($LaptopCheck -eq "Y") 
    {
        $AttachmentArray = @($systeminfofile, $InfoDump1file, $BatteryReportfile, $healthcheckarrayfile)
    }

#Emailing Information
$EmailPass = "*REMOVED*"
$PasswordEmail = ConvertTo-SecureString $EmailPass -AsPlainText -Force
$from = "landrylabs.bot@sparkhound.com";
$To = "daniel.landry@sparkhound.com";
$Attachments = $systeminfofile
$Port = 587
$Body = $healthcheckarray
$Subject = "HardwareHealthCheck(WIP) for $hostname"
$SMTPserver = "smtp.office365.com"
$Cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $from, $PasswordEmail
$Signature = "`n`nThank you,`nLandryLabs `nAutomation Assistant `nQuestions? Email 'mi-t2@sparkhound.com'"

Send-MailMessage -from $From -To $To -Subject $Subject -Body "$Body`n`n$signature" -Attachments $AttachmentArray -SmtpServer $SMTPserver -Credential $Cred -Verbose -UseSsl -Port $Port