<#

#      || LANDRY LABS - UNTITLED MONITORING SCRIPT
#      || SUMMARY: T.B.D. 
# #    ||  
####   ||  
  #    || 
  #### || Written by Daniel Landry (daniel.landry@sparkhound.com)

#>



#Rough draft for a monitoring project.

    $disabledUsers = (get-aduser -Filter {enabled -eq 'False'}).samaccountname;
    $enabledUsers = (get-aduser -Filter {enabled -eq 'True'}).samaccountname;
    $totalUsers = ($disabledUsers.count+$enabledUsers.Count);
    $ADOrganizationalUnits = (Get-ADOrganizationalUnit -filter *).name
    $adOU2 = (get-aduser -identity "*").distinguishedname
    
    $Date = Get-Date
    Write-Host "Landry Labs Active Directory Daily Report" $Date
    Write-Host "Enabled User Objects:" $enabledUsers.Count ($enabledUsers.Count/$totalUsers);
    Write-Host "Disabled User Objects:" $disabledUsers.Count ($disabledUsers.Count/$totalUsers);
    Write-Host "Organizational Units:" $ADOrganizationalUnits.Count
       
    
    <# foreach ($user in $disabledUsers)
        {
            $disabledUsersLocation = (get-aduser -identity $user).distinguishedname;
            $disabledUsersName = (get-aduser -identity $user).name;
                
                foreach ($path in $disabledUsersLocation)
                    {
                        if ($disabledUsersLocation -ne "CN=$disabledUsersName,OU=Disabled Accounts,DC=sparkhound,DC=com")
                                            {

                                                "$user is disabled and located outside of the disabled OU path here: $disabledUsersLocation";
                                            }
                    }
        } #>

