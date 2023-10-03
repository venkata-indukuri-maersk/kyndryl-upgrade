<#
Objective: Created to help on the upgrade in-place project for Kyndrl team | Maersk Upgrades

Created By: Jose Cavalheri (jose.cavalheri@maersk.com
Date: 27/09/2023

Main Tasks:
- Execute the following activities to move computer accounts to target OU

-- Move Computer Object from Original OU to Target OU (2016 to 2019 OU)
#>

#----------------- Set variables ----------------
#Virtual Machine Names : Example:  '2016upgrade05','2016upgrade03','2016upgrade06' 
$vmNames = '2016upgrade05','2016upgrade06','2016upgrade07'

# Set Target OU
$targetOU = 'OU=2019,OU=Servers,OU=Kyndryl,DC=vra4u,DC=local'

#----------------- Set Modules ----------------
#AD Module
Import-Module ActiveDirectory 

# This will trigger an execution to do multiple machines
foreach ($vmName in $vmNames){
    #----------------- Adjust Computer Account in AD ----------------
    #Identify the AD Computer Object
    $adComputer = Get-ADComputer -Identity $vmName

    #move Object to Target OU
    write-host "Moving AD Account to Target OU:  "$vmName
    Move-ADObject -Identity $adComputer -TargetPath $targetOU
}# Finish Move of AD Computer Account Objects

write-host '******************' -backgroundcolor green -foregroundcolor white
write-host 'All Computer Accounts moved to Target OU' -backgroundcolor green -foregroundcolor white
write-host '******************' -backgroundcolor green -foregroundcolor white