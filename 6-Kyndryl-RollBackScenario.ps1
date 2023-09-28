<#
Objective: Created to help on the upgrade in-place project for Kyndrl team | Maersk Upgrades

Created By: Jose Cavalheri (jose.cavalheri@maersk.com
Date: 27/09/2023

Main Tasks:
- Execute the following activities to start Roll Back Process

-- Move Computer Object from Target OU to Original OU (2019 to 2016 OU)
-- Shutdown Virtual Machine
-- Revert to Snapshot ( to original state - in this case prior to upgrade - Windows 2016 version)
-- 


#>

#----------------- Set variables ----------------

#Virtual Machine Names : Example:  '2016upgrade05','2016upgrade03','2016upgrade06' 
#$vmName = '2016upgrade02'
$vmNames = '2016upgrade05','2016upgrade06','2016upgrade07'


# Set Target Roll Back OU
$targetOU = 'OU=2016,OU=Servers,OU=Kyndryl,DC=vra4u,DC=local'


#----------------- Set Modules ----------------

#AD Module
Import-Module ActiveDirectory 



# This will trigger an execution to do multiple machines
foreach ($vmName in $vmNames){


    #----------------- Adjust Computer Account in AD ----------------
    #Identify the AD Computer Object
    $adComputer = Get-ADComputer -Identity $vmName

    #move Object to Target OU
    write-host "Roll back AD account for "$vmName
    Move-ADObject -Identity $adComputer -TargetPath $targetOU

    #----------------- Start code ----------------
    #Get Virtual Machine in vCenter / ID
    write-host "#Get Virtual Machine in vCenter / ID"
    $vm = get-vm -Name $vmName
    $vmId = get-vm -Name $vmName | Select-Object Id
    $vmId = $vmId.id

    #---------------ShutdownGuest---------------
    write-host "#Shutdown Virtual Machine" $vmName
    $_this = Get-View -Id $vmId
    $_this.ShutdownGuest()

    # Loop until the VM is powered off (offline)
    while ((Get-VM -Name $vmName).PowerState -ne "PoweredOff") {
        Write-Host "The virtual machine '$vmName' is still online."
    
        # Wait for a specified interval (e.g., 10 seconds) before checking again
        Start-Sleep -Seconds 10
    }

    #---------------RevertToSnapshot to Prior of Upgrade---------------
    $snap = Get-Snapshot -VM $vm | Sort-Object -Property Created -Descending | Select -First 1
    Set-VM -VM $vm -SnapShot $snap -Confirm:$false

    #---------------Delete Upgrade Snapshot of Upgrade---------------
    Remove-Snapshot -Snapshot $snap  -RemoveChildren -Confirm:$false

    #---------------PowerOnMultiVM_Task---------------
    # Wait for vmtools to be up and running
    write-Host "# Wait for vmtools to be up and running" 
    Start-VM $vmName | Wait-Tools

    #---------------Roll Back Completed---------------
    write-host "Roll Back Completed for vm: " $vmName -BackgroundColor green

}# Finish Roll Back all machines

write-host '******************' -backgroundcolor green -foregroundcolor white
write-host 'All machines roll back successfully' -backgroundcolor yellow -foregroundcolor red
write-host '******************' -backgroundcolor green -foregroundcolor white