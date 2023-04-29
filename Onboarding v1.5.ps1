<#

#      || LANDRY LABS - ONBOARDING SCRIPT (Updated 04/08/2023)
#      || SUMMARY: 1. Creates on-prem user object and populates with verified user information.;
# #    || -------- 2. Provisions mailbox and cloud group SSO access;
####   || -------- 3. Pushes out email to mi-t2 with transcription note & separate email to HR with initial password.;
  #    || 
  #### || Written by Daniel Landry (daniel.landry@sparkhound.com)

#>

<#----------TO DO:
-BUILD:
-FIX:
-IMPROVE:
----------#>

<#----------Change Log:
(04/08): Corrected an issue causing UKG cloud group to not be assigned when requested.
(04/08): The personal email is now properly added to the "notes" field in their AD account.
(04/08): The "Office" fiel
----------#>

$Host.UI.RawUI.WindowTitle = "Sparkhound Onboarding v1.5"
Start-Transcript -Path "$(Get-Location)\Onboardings\OnboardingTranscript.txt"
$TimeStart = Get-Date

#==========^==========#
#START OF FUNCTIONS
#==========V==========#

function ObtainFirstName
    {
                
        $FirstName = Read-Host "First Name";
        Write-Host "Submitted First Name: $FirstName"
        Return $FirstName;
    }
function ObtainLastName
    {
                
        $LastName = Read-Host "Last Name";
        Write-Host "Submitted Last Name: $LastName"
        Return $LastName;
    }
function ObtainFullName
    {
        $Name = "$FirstName $LastName";
        Write-Host "Declared Full Name: $Name"
        Return $Name;
    }
function ObtainUserName #Only changes through input of first and last name functions.
    {
                $usernameAvailable = "N"
                $username = "$FirstName.$LastName";
                $userExistsCheck = (get-aduser -filter {samaccountname -like $username}).samaccountname #Verify if username is already in use.
                Write-Host "Verifying '$username'..." -NoNewline
                start-sleep 1
                    if ($username -eq $userExistsCheck)
                        {
                            $usernameAvailable = "N";
                            Write-Host "ALREADY IN USE!" -ForegroundColor Red;
                            Get-ADUser -Identity $username;
                            ObtainFirstName;
                            ObtainLastName;
                            ObtainUserName;
                        }
                    else 
                        {
                            $usernameAvailable = "Y";
                            Write-Host "AVAILABLE TO USE!" -ForegroundColor Green;
                            return $username
                        }
    }
function ObtainEmailAddress
    {
        $EmailAddress = "$username@sparkhound.com";
        Write-Host "Declared Email: $EmailAddress"
        return $EmailAddress;
    }
function ObtainTitle
    {
        $Title = Read-Host "Title";
        Write-Host "Submitted Title $Title"
        $TitleUKGCheck = $Title.IndexOf("-");
        if ($TitleUKGCheck -ne "-1")
            {
                $Title = $Title.Split("-")
                $Title = $Title[1];
            }
        Write-Host "Verified Title: $Title"
        Return $Title;
        #Do not allow the acroymn titles in UKG to be submitted.
        #Will need to strip away UKG prefix.
    }
function ObtainRegion
    {
        #ONLY accept the following regions: Baton Rouge(BTR), Birmingham(BHM), Dallas(DFW), Houston(HOU), N/A;
        $Region = Read-Host "Region (Baton Rouge, Houston, Dallas, Birmingham)";
        Write-Host "Submitted Region: $Region"
        $RegionUKGCheck = $Region.IndexOf("-");
        if ($RegionUKGCheck -ne "-1")
            {
                $Region = $Region.Split("-")
                $Region = $Region[1];
            }
        if ($Region -eq "Baton Rouge" -or $Region -eq "Birmingham" -or $Region -eq "Dallas" -or $Region -eq "Houston")
            {
                Write-Host "Verified Region: $Region"
                Return $Region;
            }
        else 
            {
                Write-Host "Invalid region. Try again."
                ObtainRegion
            }
    }
function ObtainPhoneNumber
    {
        #OPTIONAL/EXTRA: Force Formatting restrictions on submission.
        $PhoneNumber = Read-Host "Phone Number";
        Write-Host "Submitted Phone Number: $PhoneNumber"
        Return $PhoneNumber;        
    }
function ObtainPersonalEmail
    {
        #OPTIONAL/EXTRA: Force Formatting restrictions on submission.
        $PersonalEmail = Read-Host "Personal Email";
        Write-Host "Submitted Personal Email: $PersonalEmail"
        Return $PersonalEmail;
        
    }
function ObtainCompany
    {
        $Company = Read-Host "Company ('Sparkhound' or Contracting Company)";
        Write-Host "Submitted Company: $Company"
        if ($company -ne "Sparkhound") 
            {
                "Setting $username as a contractor"; 
                $Contractor = "Y"; 
                $Title = "Contractor ($company)";
            } 
        else 
            {
                $Contractor = "N"
            };
        Return $Company;
    }
function ObtainManager
    {
        $Manager = Read-Host "Manager's username (Enter 'N' to not assign a manager)"; #Verify manager. Allow option to process without.
        Write-Host "Verifying manager '$Manager'..." -NoNewline
        Start-sleep 1
        if ($Manager -eq 'N') #Manual bypass of manager assignment.
            {
                Write-Host "NO MANAGER ASSIGNED. SKIPPING." -ForegroundColor Green;
                $Manager = "$Null"
                $managerAssigned = "Y"
                return $manager
            }
        else
            {
                $managerExistsVerification = (get-aduser -filter {samaccountname -like $Manager}).samaccountname
                    if ($Null -ne $managerExistsVerification) #Manager automatically matched.
                        {
                            $Manager = $managerExistsVerification;
                            $managerUpper = $Manager.ToUpper();
                            Write-Host "..." -NoNewline
                            Write-Host "'$ManagerUpper' ASSIGNED SUCCESSFULLY." -ForegroundColor Green;
                            $managerAssigned = "Y"
                            return $manager
                        }   
                    elseif ($managerExistsVerification -eq $Null)
                        {
                            #Write-Host "UNABLE TO VERIFY" -ForegroundColor Red -NoNewline
                            Start-sleep 1
                            Write-Host "..." -NoNewline
                            $managerFormattingCheck1 = $manager.indexOf("."); #Checking if '.' (period) character is present (standard username formatting) to use it as delimmiter.
                            $managerFormattingCheck2 = $manager.indexOf(" "); #Checking if ' ' (space) character is present (standard UKG name formatting) to use it as delimmiter.
                                if ($managerFormattingCheck1 -ne "-1")
                                    {
                                        $managerString = "$Manager";
                                        $managerStringSplit = $managerString.Split(".");
                                            foreach ($string in $managerStringSplit)
                                                {
                                                    $managerWildcard = "*$string*";
                                                    $managerExistsVerification = (get-aduser -filter {samaccountname -like $managerWildcard}).samaccountname
                                                        $i = 0;
                                                        foreach ($entry in $managerExistsVerification) #Checking number of results. If >1, generate list. Otherwise, assign user as manager.
                                                            {
                                                                $i++
                                                            }
                                                    if ($i -eq 0)
                                                        {
                                                            Write-Host "NO USERS WERE FOUND. TRY AGAIN." -ForegroundColor Red;
                                                            $managerAssigned = "N"
                                                            break
                                                        }
                                                    elseif ($i -eq 1)
                                                        {
                                                    
                                                            Write-Host "MATCH FOUND ($managerExistsVerification)" -ForegroundColor Green -NoNewline
                                                            start-sleep 1
                                                            Write-Host "..." -NoNewline
                                                            Write-Host "ASSIGNED SUCCESSFULLY!" -ForegroundColor Green
                                                            $manager = $managerExistsVerification
                                                            $managerAssigned = "Y"
                                                            break
                                                        }
                                                    elseif ($i -gt 1)
                                                        {
                                                            start-sleep 1
                                                            Write-Host "DETECTED MULTIPLE USERNAMES`n"
                                                            Write-Host "Generating list of references (ignore duplicates). Please re-enter their username to confirm the manager."
                                                            start-sleep 1
                                                                foreach ($name in $managerExistsVerification)
                                                                    {
                                                                        $name = $name.ToLower();
                                                                        Write-Host "$name;"
                                                                    }
                                                            Write-Host "`n"
                                                            $managerAssigned = "N"
                                                            break
                                                            #Kicks back to the start to enter the proper name of the manager and allows a final validation before declaration.
                                                        }
                                                }
                                        
                                        if ($managerAssigned -eq "Y")
                                            {
                                                return $manager
                                            }
                                        else 
                                            {
                                                ObtainManager;
                                            } 
                                    }
                                elseif ($managerFormattingCheck2 -ne "-1")
                                    {
                                        $manager = $manager.Replace(" ",".")
                                        $managerString = "$Manager";
                                            foreach ($string in $managerString)
                                                {
                                                    $managerWildcard = "*$string*";
                                                    $managerExistsVerification = (get-aduser -filter {samaccountname -like $managerWildcard}).samaccountname
                                                        $i = 0;
                                                        foreach ($entry in $managerExistsVerification) #Checking number of results. If >1, generate list. Otherwise, assign user as manager.
                                                            {
                                                                $i++
                                                            }
                                                    if ($i -eq 0)
                                                        {
                                                            Write-Host "NO USERS WERE FOUND. TRY AGAIN." -ForegroundColor Red;
                                                            $managerAssigned = "N"
                                                            break
                                                        }
                                                    elseif ($i -eq 1)
                                                        {
                                                    
                                                            Write-Host "MATCH FOUND ($managerExistsVerification)" -ForegroundColor Green -NoNewline
                                                            start-sleep 1
                                                            Write-Host "..." -NoNewline
                                                            Write-Host "ASSIGNED SUCCESSFULLY!" -ForegroundColor Green
                                                            $manager = $managerExistsVerification
                                                            $managerAssigned = "Y"
                                                            break
                                                        }
                                                    elseif ($i -gt 1)
                                                        {
                                                            start-sleep 1
                                                            Write-Host "DETECTED MULTIPLE USERNAMES`n"
                                                            Write-Host "Generating list of references (ignore duplicates). Please re-enter their username to confirm the manager."
                                                            start-sleep 1
                                                                foreach ($name in $managerExistsVerification)
                                                                    {
                                                                        $name = $name.ToLower();
                                                                        Write-Host "$name;"
                                                                    }
                                                            Write-Host "`n"
                                                            $managerAssigned = "N"
                                                            break
                                                            #Kicks back to the start to enter the proper name of the manager and allows a final validation before declaration.
                                                        }
                                                }
                                        if ($managerAssigned -eq "Y")
                                            {
                                                return $manager
                                            }
                                        else 
                                            {
                                                $managerString = $managerString.Split(".");
                                                foreach ($string in $managerString)
                                                    {
                                                        $managerWildcard = "*$string*";
                                                        $managerExistsVerification = (get-aduser -filter {samaccountname -like $managerWildcard}).samaccountname
                                                            $i = 0;
                                                            foreach ($entry in $managerExistsVerification) #Checking number of results. If >1, generate list. Otherwise, assign user as manager.
                                                                {
                                                                    $i++
                                                                }
                                                        if ($i -eq 0)
                                                            {
                                                                Write-Host "NO USERS WERE FOUND. TRY AGAIN." -ForegroundColor Red;
                                                                $managerAssigned = "N"
                                                                break
                                                            }
                                                        elseif ($i -eq 1)
                                                            {
                                                        
                                                                Write-Host "MATCH FOUND ($managerExistsVerification)" -ForegroundColor Green -NoNewline
                                                                start-sleep 1
                                                                Write-Host "..." -NoNewline
                                                                Write-Host "ASSIGNED SUCCESSFULLY!" -ForegroundColor Green
                                                                $manager = $managerExistsVerification
                                                                $managerAssigned = "Y"
                                                                break
                                                            }
                                                        elseif ($i -gt 1)
                                                            {
                                                                start-sleep 1
                                                                Write-Host "DETECTED MULTIPLE USERNAMES`n"
                                                                Write-Host "Generating list of references (ignore duplicates). Please re-enter their username to confirm the manager."
                                                                start-sleep 1
                                                                    foreach ($name in $managerExistsVerification)
                                                                        {
                                                                            $name = $name.ToLower();
                                                                            Write-Host "$name;"
                                                                        }
                                                                Write-Host "`n"
                                                                $managerAssigned = "N"
                                                                break
                                                                #Kicks back to the start to enter the proper name of the manager and allows a final validation before declaration.
                                                            }
                                                    }
                                            
                                            if ($managerAssigned -eq "Y")
                                                {
                                                    return $manager
                                                }
                                            else 
                                                {
                                                    ObtainManager;
                                                }
                                            }


                                        
                                    }
                        }
            }
    }
function ObtainMirrorUser
    {
        $MirrorUser = Read-Host "MirrorUser's username (Enter 'N' to not assign a mirrorUser)"; #Verify mirrorUser. Allow option to process without.
        Write-Host "Verifying mirrorUser '$MirrorUser'..." -NoNewline
        Start-sleep 1
        if ($MirrorUser -eq 'N') #Manual bypass of mirrorUser assignment.
            {
                Write-Host "NO MIRROR-USER ASSIGNED. SKIPPING." -ForegroundColor Green;
                $MirrorUser = "$Null"
                $mirrorUserAssigned = "Y"
                return $mirrorUser
            }
        else
            {
                $mirrorUserExistsVerification = (get-aduser -filter {samaccountname -like $MirrorUser}).samaccountname
                    if ($Null -ne $mirrorUserExistsVerification) #MirrorUser automatically matched.
                        {
                            $MirrorUser = $mirrorUserExistsVerification;
                            $mirrorUserUpper = $MirrorUser.ToUpper();
                            Write-Host "..." -NoNewline
                            Write-Host "'$MirrorUserUpper' ASSIGNED SUCCESSFULLY." -ForegroundColor Green;
                            $mirrorUserAssigned = "Y"
                            return $mirrorUser
                        }   
                    elseif ($mirrorUserExistsVerification -eq $Null)
                        {
                            #Write-Host "UNABLE TO VERIFY" -ForegroundColor Red -NoNewline
                            Start-sleep 1
                            Write-Host "..." -NoNewline
                            $mirrorUserFormattingCheck1 = $mirrorUser.indexOf("."); #Checking if '.' (period) character is present (standard username formatting) to use it as delimmiter.
                            $mirrorUserFormattingCheck2 = $mirrorUser.indexOf(" "); #Checking if ' ' (space) character is present (standard UKG name formatting) to use it as delimmiter.
                                if ($mirrorUserFormattingCheck1 -ne "-1")
                                    {
                                        $mirrorUserString = "$MirrorUser";
                                        $mirrorUserStringSplit = $mirrorUserString.Split(".");
                                            foreach ($string in $mirrorUserStringSplit)
                                                {
                                                    $mirrorUserWildcard = "*$string*";
                                                    $mirrorUserExistsVerification = (get-aduser -filter {samaccountname -like $mirrorUserWildcard}).samaccountname
                                                        $i = 0;
                                                        foreach ($entry in $mirrorUserExistsVerification) #Checking number of results. If >1, generate list. Otherwise, assign user as mirrorUser.
                                                            {
                                                                $i++
                                                            }
                                                    if ($i -eq 0)
                                                        {
                                                            Write-Host "NO USERS WERE FOUND. TRY AGAIN." -ForegroundColor Red;
                                                            $mirrorUserAssigned = "N"
                                                            break
                                                        }
                                                    elseif ($i -eq 1)
                                                        {
                                                    
                                                            Write-Host "MATCH FOUND ($mirrorUserExistsVerification)" -ForegroundColor Green -NoNewline
                                                            start-sleep 1
                                                            Write-Host "..." -NoNewline
                                                            Write-Host "ASSIGNED SUCCESSFULLY!" -ForegroundColor Green
                                                            $mirrorUser = $mirrorUserExistsVerification
                                                            $mirrorUserAssigned = "Y"
                                                            break
                                                        }
                                                    elseif ($i -gt 1)
                                                        {
                                                            start-sleep 1
                                                            Write-Host "DETECTED MULTIPLE USERNAMES`n"
                                                            Write-Host "Generating list of references (ignore duplicates). Please re-enter their username to confirm the mirrorUser."
                                                            start-sleep 1
                                                                foreach ($name in $mirrorUserExistsVerification)
                                                                    {
                                                                        $name = $name.ToLower();
                                                                        Write-Host "$name;"
                                                                    }
                                                            Write-Host "`n"
                                                            $mirrorUserAssigned = "N"
                                                            break
                                                            #Kicks back to the start to enter the proper name of the mirrorUser and allows a final validation before declaration.
                                                        }
                                                }
                                        
                                        if ($mirrorUserAssigned -eq "Y")
                                            {
                                                return $mirrorUser
                                            }
                                        else 
                                            {
                                                ObtainMirrorUser;
                                            } 
                                    }
                                elseif ($mirrorUserFormattingCheck2 -ne "-1")
                                    {
                                        $mirrorUserString = "$MirrorUser";
                                        $mirrorUserStringSplit = $mirrorUserString.Split(" ");
                                            foreach ($string in $mirrorUserStringSplit)
                                                {
                                                    $mirrorUserWildcard = "*$string*";
                                                    $mirrorUserExistsVerification = (get-aduser -filter {samaccountname -like $mirrorUserWildcard}).samaccountname
                                                        $i = 0;
                                                        foreach ($entry in $mirrorUserExistsVerification) #Checking number of results. If >1, generate list. Otherwise, assign user as mirrorUser.
                                                            {
                                                                $i++
                                                            }
                                                    if ($i -eq 0)
                                                        {
                                                            Write-Host "NO USERS WERE FOUND. TRY AGAIN." -ForegroundColor Red;
                                                            $mirrorUserAssigned = "N"
                                                            break
                                                        }
                                                    elseif ($i -eq 1)
                                                        {
                                                    
                                                            Write-Host "MATCH FOUND ($mirrorUserExistsVerification)" -ForegroundColor Green -NoNewline
                                                            start-sleep 1
                                                            Write-Host "..." -NoNewline
                                                            Write-Host "ASSIGNED SUCCESSFULLY!" -ForegroundColor Green
                                                            $mirrorUser = $mirrorUserExistsVerification
                                                            $mirrorUserAssigned = "Y"
                                                            break
                                                        }
                                                    elseif ($i -gt 1)
                                                        {
                                                            start-sleep 1
                                                            Write-Host "DETECTED MULTIPLE USERNAMES`n"
                                                            Write-Host "Generating list of references (ignore duplicates). Please re-enter their username to confirm the mirrorUser."
                                                            start-sleep 1
                                                                foreach ($name in $mirrorUserExistsVerification)
                                                                    {
                                                                        $name = $name.ToLower();
                                                                        Write-Host "$name;"
                                                                    }
                                                            Write-Host "`n"
                                                            $mirrorUserAssigned = "N"
                                                            break
                                                            #Kicks back to the start to enter the proper name of the mirrorUser and allows a final validation before declaration.
                                                        }
                                                }
                                        
                                        if ($mirrorUserAssigned -eq "Y")
                                            {
                                                return $mirrorUser
                                            }
                                        else 
                                            {
                                                ObtainMirrorUser;
                                            }
                                    }
                        }
            }
    }
function ObtainStartDate
    {
        $StartDate = Read-Host "Start Date"
        Write-Host "Submitted Start Date: $StartDate"
        Return $StartDate;
    }
function ObtainPractice
    {
        

        #Verify the given OU exists.
        #Example UKG Practice: 'AUTSVC-Automation Services'
        #"OU=$Practice,OU=Domain Users,DC=sparkhound,DC=com"
        $Practice = Read-Host "Practice";
        $PracticeOUPath = "OU=$Practice,OU=Domain Users,DC=sparkhound,DC=com" 
        Write-Host "Verifying Practice '$Practice'..." -NoNewline
        Start-sleep 1
        $practiceOUCHeck1 = (Get-ADObject -Filter "identity -like '$PracticeOUPath'").distinguishedname #VERIFY CHECK 1
        Write-Host "..." -NoNewline
        if ($Null -ne $practiceOUCHeck1)
            {
                
                Write-Host "ASSIGNED SUCCESSFULLY" -ForegroundColor Green;
                $PracticeOUAssigned = "Y";
                return $practiceOUCHeck1;
            }
        else 
            {
                #Write-Host "UNABLE TO VERIFY" -NoNewline -ForegroundColor Red
                Write-Host "..." -NoNewline
                $practiceFormattingCheckDash = $practice.IndexOf("-"); #Checks if the UKG formatted practice was submitted.
                $PracticeString = "$Practice"
                if ($practiceFormattingCheckDash -ne "-1")
                    {
                        $PracticeStringSplit = $PracticeString.Split("-"); #Breaks apart the UKG prefix string from the actual OU name.
                        $PracticeStringSplit = $PracticeStringSplit[1]#.Split(" ");
                    }
                <# else 
                    {
                        $PracticeStringSplit = $PracticeString.Split(" "); #Breaks apart the OU name into separate searchable words.
                        $PracticeStringSplit
                    } #>
                    foreach ($string in $PracticeStringSplit)
                        {
                            $practiceSearchWildcard = "*$string*";
                            $practiceSearchVerification = (Get-ADObject -filter "name -like '$practiceSearchWildcard'" -SearchBase "OU=Domain Users,DC=sparkhound,DC=com" -SearchScope OneLevel).name
                                $i = 0;
                                foreach ($item in $practiceSearchVerification)
                                    {
                                        $i++
                                    }
                            if ($i -eq 0)
                                {
                                    Write-Host "NO PRACTICE WAS FOUND. TRY AGAIN." -ForegroundColor Red;
                                    $PracticeAssigned = "N"
                                    break
                                }
                            elseif ($i -eq 1)
                                {
                            
                                    Write-Host "MATCH FOUND ($practiceSearchVerification)" -ForegroundColor Green -NoNewline
                                    start-sleep 1
                                    Write-Host "..." -NoNewline
                                    Write-Host "ASSIGNED SUCCESSFULLY!" -ForegroundColor Green
                                    $Practice = $practiceSearchVerification
                                    $PracticeAssigned = "Y"
                                    break
                                }
                            elseif ($i -gt 1)
                                {
                                    start-sleep 1
                                    Write-Host "DETECTED MULTIPLE PRACTICES`n"
                                    Write-Host "Generating list of references (ignore duplicates). Please enter your submission again using the reference."
                                    start-sleep 1
                                        foreach ($name in $practiceSearchVerification)
                                            {
                                                $name = $name.ToLower();
                                                Write-Host "$name;"
                                            }
                                    Write-Host "`n"
                                    $PracticeAssigned = "N"
                                    break
                                }
                        }
                    if ($PracticeAssigned -eq "Y")
                        {
                            return $Practice
                        }
                    else 
                        {
                            ObtainPractice;
                        } 
                        
            }                    
    }
function ObtainDepartment ($Practice)
    {
        #Verify the given OU exists.
        #Example UKG Department: 'SVCDSK-Tier 1'
        #"OU=$department,OU=$Practice,OU=Domain Users,DC=sparkhound,DC=com"
        $Department = Read-Host "Department";
        $DepartmentOUPath = "OU=$Practice,OU=Domain Users,DC=sparkhound,DC=com"
        Write-Host "Verifying Department '$Department'..." -NoNewline
        Start-sleep 1
        $departmentOUCHeck1 = (Get-ADObject -Filter "name -like '$Department'" -SearchBase "$DepartmentOUPath" -SearchScope Subtree).name #VERIFY CHECK 1
        if ($Null -ne $departmentOUCHeck1)
            {
                Write-Host "..." -NoNewline
                Write-Host "ASSIGNED SUCCESSFULLY" -ForegroundColor Green;
                $DepartmentOUAssigned = "Y";
                return $departmentOUCHeck1;
            }
        else 
            {
                #Write-Host "UNABLE TO VERIFY" -NoNewline -ForegroundColor Red
                Write-Host "..." -NoNewline
                $departmentFormattingCheckDash = $department.IndexOf("-"); #Checks if the UKG formatted department was submitted.
                $DepartmentString = "$Department"
                if ($departmentFormattingCheckDash -ne "-1")
                    {
                        $DepartmentStringSplit = $DepartmentString.Split("-"); #Breaks apart the UKG prefix string from the actual OU name.
                        $DepartmentStringSplit = $DepartmentStringSplit[1]#.Split(" ");
                    }
                <# else 
                    {
                        $DepartmentStringSplit = $DepartmentString.Split(" "); #Breaks apart the OU name into separate searchable words.
                        $DepartmentStringSplit
                    } #>
                    foreach ($string in $DepartmentStringSplit)
                        {
                            $departmentSearchWildcard = "*$string*";
                            $departmentSearchVerification = (Get-ADObject -filter "name -like '$departmentSearchWildcard'" -SearchBase "$DepartmentOUPath" -SearchScope Subtree).name
                                $i = 0;
                                foreach ($item in $departmentSearchVerification)
                                    {
                                        $i++
                                    }
                            if ($i -eq 0)
                                {
                                    Write-Host "NO MATCH WAS FOUND. TRY AGAIN." -ForegroundColor Red;
                                    $DepartmentAssigned = "N"
                                    break
                                }
                            elseif ($i -eq 1)
                                {
                            
                                    Write-Host "MATCH FOUND ($departmentSearchVerification)" -ForegroundColor Green -NoNewline
                                    start-sleep 1
                                    Write-Host "..." -NoNewline
                                    Write-Host "ASSIGNED SUCCESSFULLY!" -ForegroundColor Green
                                    $Department = $departmentSearchVerification
                                    $DepartmentAssigned = "Y"
                                    break
                                }
                            elseif ($i -gt 1)
                                {
                                    start-sleep 1
                                    Write-Host "DETECTED MULTIPLE MATCHES`n"
                                    Write-Host "Generating list of references (ignore duplicates). Please enter your submission again using the reference."
                                    start-sleep 1
                                        foreach ($name in $departmentSearchVerification)
                                            {
                                                $name = $name.ToLower();
                                                Write-Host "$name;"
                                            }
                                    Write-Host "`n"
                                    $DepartmentAssigned = "N"
                                    break
                                }
                        }
                    if ($DepartmentAssigned -eq "Y")
                        {
                            return $Department
                        }
                    else 
                        {
                            ObtainDepartment;
                        } 
                        
            }                    
    }

function ObtainBusinessUnit ($Practice)
    {
        if ($Practice -eq "Automation Services" -or $Practice -eq "Business Process Mgt")
            {
                $BusinessUnit = "Digital Automation";
            }
        if ($Practice -eq "Contact Center Operations")
            {
                $BusinessUnit = "Contact Center Operations";
            }
        if ($Practice -eq "Support Services" -or $Practice -eq "IT Modernization Services")
            {
                $BusinessUnit = "Managed Infrastructure";
            }
        if ($Practice -eq "Shared Services" -or "Corp")
            {
                $BusinessUnit = "Corporate";
            }
        return $BusinessUnit
    }
function ObtainUserOUPath ($Department, $Practice)
    {
        $UserOUPath = "OU=$Department,OU=$Practice,OU=Domain Users,DC=sparkhound,DC=com"
        Write-Host "Declared OU Path: $userOUPath"
        return $UserOUPath;
    }
function ObtainCloudItemUKG
    {
        #Only allow "Yes" or "No".
        $UKGSSO = Read-Host "UKG SSO Yes/No"
        Write-Host "Submitted UKG Selection: $UKGSSO"
        $UGKSSOCheck = $UKGSSO.IndexOf(" ")
        if ($UKGSSOCheck -ne "-1")
            {
                $UKGSSO = $UKGSSO.Split(" ");
            }
        foreach ($item in $UKGSSO)
            {
                switch ($item)
                    {
                        "Yes" 
                            {
                                $UKGVerified = "Y"
                                $UKGSSO = $item
                                break
                            }
                        "No" 
                            {
                                $UKGVerified = "Y"
                                $UKGSSO = $item
                                break
                            }
                        default 
                            {
                                $UKGVerified = "N"
                                break
                            }
                    }
            }
        if ($UKGVerified -eq "Y")
            {
                Return $UKGSSO;
            }
        else
            {
                ObtainCloudItemUKG
            }
    }
function ObtainCloudItemOA
    {
         #Only allow "Yes" or "No".
         $OpenAirSSO = Read-Host "OpenAir SSO Yes/No"
         Write-Host "Submitted OpenAir Selection: $OpenAirSSO"
         $OpenAirSSOCheck = $OpenAirSSO.IndexOf(" ")
         if ($OpenAirSSOCheck -ne "-1")
             {
                 $OpenAirSSO = $OpenAirSSO.Split(" ");
             }
         foreach ($item in $OpenAirSSO)
             {
                 switch ($item)
                     {
                         "Yes" 
                             {
                                 $OpenAirVerified = "Y"
                                 $OpenAirSSO = $item
                                 break
                             }
                         "No" 
                             {
                                 $OpenAirVerified = "Y"
                                 $OpenAirSSO = $item
                                 break
                             }
                     }
                 }
             if ($OpenAirVerified -eq "Y")
                 {
                     Return $OpenAirSSO;
                 }
             else
                 {
                     ObtainCloudItemOA
                 }
    }
function ObtainCloudItemNetSuite
    {
        #Only allow "Yes" or "No".
        $NetSuiteSSO = Read-Host "NetSuite SSO Yes/No"
        Write-Host "Submitted NetSuite Selection: $NetSuiteSSO"
        $NetSuiteSSOCheck = $NetSuiteSSO.IndexOf(" ")
        if ($NetSuiteSSOCheck -ne "-1")
            {
                $NetSuiteSSO = $NetSuiteSSO.Split(" ");
            }
        foreach ($item in $NetSuiteSSO)
            {
                switch ($item)
                    {
                        "Yes" 
                            {
                                $NetSuiteVerified = "Y"
                                $NetSuiteSSO = $item
                                break
                            }
                        "No" 
                            {
                                $NetSuiteVerified = "Y"
                                $NetSuiteSSO = $item
                                break
                            }
                    }
                }
            if ($NetSuiteVerified -eq "Y")
                {
                    Return $NetSuiteSSO;
                }
            else
                {
                    ObtainCloudItemNetSuite
                }
    }
function ObtainTempPassword
    {
        #ONLY accept "*REMOVED*" as a valid submission.
        $PasswordRequest = Read-Host "New User Password (Only '*REMOVED*' is accepted)"
        if ($PasswordRequest -ne "*REMOVED*")
            {
                Write-Host "Invalid. Enter '*REMOVED*' to continue." -ForegroundColor Red
                ObtainTempPassword
            }
        $Password = ConvertTo-SecureString $PasswordRequest -AsPlainText -Force
        Return $Password;
    }

Function Menu #SCRIPT GREETING AND REQUESTING CONFIRMATION TO START ONBOARDING OR EXIT.

#      || LANDRY LABS - ONBOARDING SCRIPT
#      || SUMMARY: 1. Creates on-prem user object and populates with verified user information.;
# #    || -------- 2. Provisions mailbox and cloud group SSO access;
####   || -------- 3. Pushes out email to mi-t2 with transcription note & separate email to HR with initial password.;
  #    || 
  #### || Written by Daniel Landry (daniel.landry@sparkhound.com)

    {
        "`n"
        Write-Host "  #      " -ForegroundColor DarkGreen -NoNewline
        Write-Host "|| LANDRY LABS - ONBOARDING SCRIPT (Updated 04/08/2023)"
        Write-Host "  #      " -ForegroundColor DarkGreen -NoNewline
        Write-Host "|| SUMMARY: 1. Creates on-prem user object and populates with verified user information."
        Write-Host "  # #    " -ForegroundColor DarkGreen -NoNewline
        Write-Host "|| -------- 2. Provisions mailbox and cloud group SSO access"
        Write-Host "  ####   " -ForegroundColor DarkGreen -NoNewline
        Write-Host "|| -------- 3. Pushes out email to mi-t2 with transcription note & separate email to HR with initial password."
        Write-Host "    #    " -ForegroundColor DarkGreen -NoNewline
        Write-Host "|| " 
        Write-Host "    #### " -ForegroundColor DarkGreen -NoNewline
        Write-Host "|| Written by Daniel Landry (daniel.landry@sparkhound.com)`n"
        Write-Host "Enter 'Y': Begin a standard onboarding."
        #Write-Host "Enter 'T': Onboard a test account." #Might just become 'TEST MODE' with further options.
        #Write-Host "Enter 'R': Restore standard security levels (MFA and temp password)"
        Write-Host "Enter 'N': Exit"
        $Begin = Read-Host "(Y/N/T/R)"
            do 
                {
                    if ($Begin -eq "Y")
                        {
                            Connect-AzureAD
                            Import-module -name ActiveDirectory
                            return;
                            
                        }
                    elseif ($Begin -eq "N")
                        {
                            Stop-Transcript
                            exit;
                        }
                    elseif ($Begin -eq "T")
                        {
                            #TEST ONBOARDING - Intended functions:
                            #Requests technician email to push results of onboarding test and CC's daniel.landry@sparkhound.com for visibililty.
                            #Disables onboarding email push to HR.
                        }
                    elseif ($Begin -eq "R")
                        {
                            #RESTORES SECURITY LEVELS
                            #Requests username and checks for the following:
                                #Removes the user from cloud group "MFA Exemptions" to prevent bypassing MFA.
                                #Restores active toggle of "user must change password at next login" in on-prem account.
                        }
                    else
                        {
                            "Invalid option."
                            Program;
                        }
                }
            until ($Begin -eq "Y" -or $Begin -eq "N") 
     }

Function TestOnboarding
     {

     }

#==========^==========#
#END OF FUNCTIONS
#==========V==========#

Menu; #Script starts interaction with this 'Program' function.

#==========^==========#
#Step 1 - REQUESTING ONBOARDING INFORMATION
#==========v==========#

Write-Host "Step 1 - Supply onboarding user information for verification";
$FirstName = ObtainFirstName;
$LastName = ObtainLastName;
$Name = ObtainFullName;
$UserName = ObtainUserName;
$EmailAddress = ObtainEmailAddress;
$PhoneNumber = ObtainPhoneNumber;
$PersonalEmail = ObtainPersonalEmail;
$StartDate = ObtainStartDate;
$Region = ObtainRegion;
$Practice = ObtainPractice 
$Department = ObtainDepartment -Practice $Practice;
$UserOUPath = ObtainUserOUPath -Practice $Practice -Department $Department
$Manager = ObtainManager;
$Title = ObtainTitle;
$Company = ObtainCompany;
$BusinessUnit = ObtainBusinessUnit -Practice $Practice;
$MirrorUser = ObtainMirrorUser;
$UKGSSO = ObtainCloudItemUKG;
$OpenAirSSO = ObtainCloudItemOA;
$NetSuiteSSO = ObtainCloudItemNetSuite;
$Password = ObtainTempPassword;
$ContractLabor = "CN=Contract Labor,OU=Contract Labor,OU=Sharepoint Groups,OU=Security Groups,DC=sparkhound,DC=com"
<#Division Field:
    "Digital Automation" ('Digital Transformation' in UKG)
        'GRP_DA_ALL'
        'GRP_DA_INDUSTRY' (Department -eq 'Industry')
        'GRP_DA_PROJECT MANAGEMENT (Department -eq 'Project Management')
        'GRP_DA_Packaged SW/LCNC/RPA' (Department -eq 'Packaged Software')
        'GRP_DA_Technology' (ExtensionAttribute4 -eq 'Technology')
        'GRP_DA_Web & Mobile' (Department -eq 'Web & Mobile')
        'GRP_DA_Analytics/ML/AI' (Department -eq 'Analytics')
        'GRP_DA_Strategy' (Department -eq 'Strategy')
        'GRP_DA_Process' (ExtensionAttribute4 -eq 'Process')
        'GRP_DA_Sales' (Department -eq 'Sales')

    "Managed Infrastructure" ('Managed Services' in UKG)
        'GRP_MI_ALL'
        'GRP_MI_Tier III' (Department -eq 'Tier III')
        'GRP_MI_Field Services' (Department -eq 'Field Services')
        'GRP_MI_Support Services' (extensionAttribute4 -eq 'Support Services')
        'GRP_MI_Consulting Services' (department -eq "Consulting" OR extensionAttribute3 -match 'MI')
        'GRP_MI_Tier II' (Department -eq 'Tier II')
        'GRP_MI_Service Desk' (Department -eq 'Service Desk')
        'GRP_MI_Sales' (Department -eq 'Sales')

    "Corporate" ('Corporate' in UKG)
        'GRP_Corporate_ALL'
        'GRP_Corporate_Accounting' (Department -eq 'Accounting')
        'GRP_Corporate_ELT' (Department -eq 'asdf')
        'GRP_Corporate_SLED' (ExtensionAttribute4 -eq 'SLED')
        'GRP_Corporate_Sales/Partnerships' (ExtensionAttribute4 -eq 'Sales/Partnerships')
    "Contact Center Operations" ('Contact Center Operations' in UKG)
#>




#==========^==========#
#Step 2: Create user object
#==========V==========#
"Step 2 - Starting account creation..."
New-ADUser -Name "$Name" -samaccountname $username -UserPrincipalName $EmailAddress -AccountPassword $Password -Enabled $true -ChangePasswordAtLogon $false -GivenName $FirstName -Surname $LastName -DisplayName $Name -City $Region -Office $Region -Company $Company -Department $Department -Description $Title -EmailAddress $EmailAddress -Manager $Manager -MobilePhone $PhoneNumber -Title $Title -OfficePhone $PhoneNumber -OtherAttributes @{'info'=$PersonalEmail}
#-OtherAttributes @{'notes'=$PersonalEmail}
$CheckAccountCreation = (get-aduser -Identity $username -properties *).userprincipalname
    if ($CheckAccountCreation -eq $EmailAddress) 
        {
            "Account created for $Name. Information populated."
        } 
    else 
        {
            "Account not created. Please investigate."
        }

Start-sleep 3
#==========^==========#
#Step 3: Mirror security groups from target user
#==========V==========#
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

        #Still need to work on auto switching primary group for contractors so that 'domain users' can be auto deleted.
    if ($Contractor -eq "Y")
        {
            "Adding contractor $username to Contract Labor security group..."
            Add-ADGroupMember $ContractLabor $username
        }
    else {"Not a contractor...Skipping contract labor group."}

Start-sleep 3
#==========^==========#
#Step 4: Move new user object to department OU to allow AADSyncing.
#==========V==========#
"Step 4 - Moving $username to designated OU for $Department to allow AADSync."
$UserPath = (get-aduser -identity $username -properties *).distinguishedname
move-adobject -identity $UserPath -targetpath $UserOUPath


#==========^==========#
#CONNECTING TO AZURE-AD TO CONFIRM OBJECT SYNC
#==========V==========#
"Establishing AzureAD Connection for cloud items..."

    ##Confirms detection of new user object being synced to cloud AD.
    ##If unable to locate user, wait 60 and scan again. Once found, proceed with adding the groups.
    "Waiting for $username to sync to AzureAD to proceed. Checking every 60s."
    "Visit 'SH-AZSYNC02'(172.25.1.14) and run 'Start-ADSyncSyncCycle -PolicyType Delta' to perform manual sync."
    do
        {
            Write-Host "#" -NoNewline
            #Add "(Get-AzureADTenantDetail).companylastdirsynctime" timestamp into waiting output.
            $NewUserCLoudSynced = (get-azureaduser -filter "userprincipalname eq '$EmailAddress'").userprincipalname
            sleep 60
        }
    Until ($NewUserCloudSynced -eq "$EmailAddress")

"`n$username detected in AzureAD."


#==========^==========#
#Step 5: Add user to applicable cloud groups (O365 license, Ultipro, netsuite, openair)
#==========V==========#
"Step 5 - Joining $username to applicable cloud groups." 

##Add new user to Business Premium license group.
"Step 5.1 - Joining $username to 'Microsoft 365 Business Premium (Cloud Group)' for mailbox access."
$MailboxGroup = (get-azureadgroup -SearchString "sg.microsoft 365 Business Premium (Cloud Group)").objectid
$NewUserObjectID = (get-azureaduser -filter "userprincipalname eq '$EmailAddress'").objectid
Add-AzureADGroupMember -objectid "$MailboxGroup" -RefObjectId "$NewUserObjectID"; 
$MSLicense = "Provisioned license for MS Office and Mailbox (sg.microsoft 365 Business Premium)";

"Step 5.2 - Joining $username to 'MFA_Exemptions' cloud group."
$MailboxGroupMFAexemptions = (get-azureadgroup -SearchString "MFA_Exemptions").objectid
Add-AzureADGroupMember -objectid "$MailboxGroupMFAexemptions" -RefObjectId "$NewUserObjectID";
$AddedToMFAExemptions = "Added to temporary 'MFA_Exemptions' cloud group.";


Start-sleep 3
    ##Add new user to UKG SSO group.
    If ($UKGSSO -eq "Yes")
        {
            "Joining $username to 'UKG' group..."
            $MailboxGroup = (get-azureadgroup -SearchString "UltiPro_Users").objectid
            $NewUserObjectID = (get-azureaduser -filter "userprincipalname eq '$EmailAddress'").objectid
            Add-AzureADGroupMember -objectid "$MailboxGroup" -RefObjectId "$NewUserObjectID"; 
            $UKGString = "Added to UKG SSO cloud group (UltiPro_Users)."
        }
    Else 
        {
            $UKGString = "UKG not requested..."
        }

    ##Add new user to OpenAir SSO group.
    If ($OpenAirSSO -eq "Yes")
        {
            "Joining $username to 'OpenAir' group..."
            $MailboxGroup = (get-azureadgroup -SearchString "OpenAir_Users_Prod").objectid
            $NewUserObjectID = (get-azureaduser -filter "userprincipalname eq '$EmailAddress'").objectid
            Add-AzureADGroupMember -objectid "$MailboxGroup" -RefObjectId "$NewUserObjectID"; 
            $OpenAirString = "Added to OpenAir SSO cloud group (OpenAir_Users_Prod)."
        }
    Else 
        {
            $OpenAirString = "OpenAir not requested..."
        }

    ##Add new user to NetSuite SSO group.
    If ($NetSuiteSSO -eq "Yes")
        {
            "Joining $username to 'NetSuite' group..."
            $MailboxGroup = (get-azureadgroup -SearchString "NetSuiteERP_Users").objectid
            $NewUserObjectID = (get-azureaduser -filter "userprincipalname eq '$EmailAddress'").objectid
            Add-AzureADGroupMember -objectid "$MailboxGroup" -RefObjectId "$NewUserObjectID"; 
            $NetsuiteString = "Added to NetSuite SSO cloud group (NetSuiteERP_Users)."
        }
    Else 
        {
            $NetsuiteString = "NetSuite not requested..."
        }
$TimeEnd = Get-Date;
Stop-Transcript

$LOGFile = Get-Content -Path "$(Get-Location)\Onboardings\OnboardingTranscript.txt"
$LOGArray = @()
    foreach ($item in $LOGFile)
        {
            $LogArray += "$item`n";
        }

#Mailing info below
$EmailPass = "*REMOVED*"
$PasswordEmail = ConvertTo-SecureString $EmailPass -AsPlainText -Force
$from = "landrylabs.bot@sparkhound.com";
#$To = "daniel.landry@sparkhound.com";
$To = "mi-t2@sparkhound.com";
#$Cc = "mi-t2@sparkhound.com";
$Port = 587
$Subject = "Account Onboarding - Complete | $EmailAddress."
$SMTPserver = "smtp.office365.com"
$Cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $from, $PasswordEmail
$Signature = "`n`nThank you,`nLandryLabs `nAutomation Assistant `nQuestions? Email 'mi-t2@sparkhound.com'."

#==========^==========#
#Technician note for CWM ticket/HR..
#==========V==========#
$CWMnote = "Start Time: $TimeStart`n"
$CWMnote = ($CWMnote + "End Time: $TimeEnd`n");
$CWMnote = ($CWMnote + "Generated note for ConnectwiseManage ticket below`n")
$CWMnote = ($CWMnote + "====================`n")
$CWMnote = ($CWMnote + "Hello HR,`n");
$CWMnote = ($CWMnote + "$EmailAddress account has been created for $Name.`n");
$CWMnote = ($CWMnote + "Initial password has been emailed directly to HR.`n");
    if ($MirrorUser -ne "N")
        {
            $CWMnote = ($CWMnote + "Mirrored security groups from $MirrorUser`n");
        } 
    else 
        {
            $CWMnote = ($CWMnote + "No user assigned to mirror security groups.`n");
        }
$CWMnote += "$MSLicense`n"
$CWNote += "$AddedToMFAExemptions`n"
$CWMnote += "$UKGString`n" #"Added to UKG SSO cloud group (UltiPro_Users)." \ "UKG not requested..."
$CWMnote += "$OpenAirString`n" #"Added to OpenAir SSO cloud group (OpenAir_Users_Prod)." \ "OpenAir not requested..."
$CWMnote += "$NetsuiteString`n" #"Added to NetSuite SSO cloud group (NetSuiteERP_Users)." \ "NetSuite not requested..."
$CWMnote = ($CWMnote + "Assigned to OU: $UserOUPath`n");
$CWMnote = ($CWMnote + "====================`n");
$CWMnote
$LogTranscriptStart = "TRANSCRIPT BELOW"
Send-MailMessage -from $From -To $To -Subject $Subject -Body "$CWMnote`n$LogTranscriptStart`n$LOGArray`n$signature" -SmtpServer $SMTPserver -Credential $Cred -Verbose -UseSsl -Port $Port


#Separate email alert pushed to HR@sparkhound.com
#$ToHR = "daniel.landry@sparkhound.com";
$ToHR = "HR@sparkhound.com";
$HRCc = "mi-t2@sparkhound.com";
$BodyHR = "Hello Hr,`n`n$EmailAddress has been created for $Name. Forwarding their initial password of '*REMOVED*'."
Send-MailMessage -from $From -To $ToHR -Cc $HRCc -Subject $Subject -Body $BodyHR`n$signature -SmtpServer $SMTPserver -Credential $Cred -Verbose -UseSsl -Port $Port






<# OLD CODE. ONLY HERE INCASE I NEED ANYTHING FROM IT.

"Please provide the following information for this onboarding:"
$TimeStart = Get-Date
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
            $Title = "Contractor ($company)";
        } 
    else 
        {
            $Contractor = "N"
        };
$Manager = Read-Host "Manager's username (First.Last)";
$MirrorUser = Read-Host "User to Mirror ('N' if not mirroring)"
$StartDate = Read-Host "Start Date"
$BusinessUnit = Read-Host "Business Unit"
$Department = Read-Host "Department";
$DepartmentConvert = "*$Department*"
$Practice = Read-Host "Practice";
$UserOUPath = "OU=$department,OU=$Practice,OU=Domain Users,DC=sparkhound,DC=com" 
$DepartmentLookup = (Get-ADOrganizationalUnit -Identity $UserOUPath)
    if ($DepartmentLookup -ne "Null") 
        {
            "Department OU of $UserOUPath confirmed and assigned."
        }
$UKGSSO = Read-Host "UKG SSO Y/N"
$OpenAirSSO = Read-Host "OpenAir SSO Y/N"
$NetSuiteSSO = Read-Host "NetSuite SSO Y/N"
$PasswordRequest = Read-Host "New User Password"
$Password = ConvertTo-SecureString $PasswordRequest -AsPlainText -Force 

OLD CODE. ONLY HERE INCASE I NEED ANYTHING FROM IT. #>
