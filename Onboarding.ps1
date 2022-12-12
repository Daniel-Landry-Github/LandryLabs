﻿"Onboarding Script"

$NewUser = DanLand.User
#Step ?: mirror security groups from target user
$MirrorUser = Read-Host "Mirror user: ". #Request the user that will be mirrored
$MirrorGroups = (get-aduser -Identity $MirrorUser -properties *).Memberof #Fetches that user's on-prem groups
$MirrorGroups
foreach ($MirrorGroupEntry in $MirrorGroups) {"Adding $NewUser to $MirrorGroupEntry"}