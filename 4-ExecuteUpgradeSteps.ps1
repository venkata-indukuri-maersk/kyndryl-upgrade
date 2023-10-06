<#
Objective: Created to help on the upgrade in-place project for 'A' team | Maersk Upgrades

Created By: Jose Cavalheri (jose.cavalheri@maersk.com
Date: 27/09/2023

Main Tasks:
- Execute the following activities to start upgrade of Windows OS 2012/2016/2019 virtual machines

-- Location of ISO to perform upgrade
-- Clean Shutdown Virtual Machine
-- Force Virtual Machine in case doesn't power off gracefully
-- Create a Snapshop for roll back purposes
-- Mount ISO on the virtual machine ( Upgrade OS ISO image)
-- MANUAL INTERVENTION TO EXECUTE SCRIPT to UPGRADE  ( You must logon to vm and execute the script on c:\\upgrade\\run_this_script_to_upgrade.ps1)
#>

#----------------- Set variables ----------------

#Virtual Machine Names : Example:  '2016upgrade05','2016upgrade03','2016upgrade06' 
#$vmName = '2016upgrade02'
$vmNames = '2016upgrade02','2016upgrade03','2016upgrade07'

# This will trigger an execution to do multiple machines
foreach ($vmName in $vmNames){


    #ISO Path for the Upgrade to be used
    $isoPath = '[CLU-LUN001] ISO/en_windows_server_2019_x64_dvd_4cb967d8.iso'


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
    $limit = 
    while ((Get-VM -Name $vmName).PowerState -ne "PoweredOff") {
        Write-Host "The virtual machine '$vmName' is still online."
    
        # Wait for a specified interval (e.g., 10 seconds) before checking again
        Start-Sleep -Seconds 10
        
        # Force shutdown after 10 minutes
        $limit += 1
        if ($limit -eq 60) {
            Write-Host "The virtual machine '$vmName' is still online. Forcing shutdown..."
            Stop-VM -VM $vmName -Confirm:$false -Force
        }

    }


    #---------------CreateSnapshot_Task---------------
    write-host "#Create a Roll back Scenario - Snapshot"
    $name = 'Automatic Upgrade'
    $description = 'Automatic Upgrade  during upgrade in place'
    $memory = $false
    $quiesce = $false
    $_this = Get-View -Id $vmId
    $_this.CreateSnapshot_Task($name, $description, $memory, $quiesce)


    # Mount CD-Rom with ISO
    #---------------ReconfigVM_Task---------------
    write-host "#Mounting the ISO on Virtual Machine"
    $spec = New-Object VMware.Vim.VirtualMachineConfigSpec
    $spec.DeviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec[] (1)
    $spec.DeviceChange[0] = New-Object VMware.Vim.VirtualDeviceConfigSpec
    $spec.DeviceChange[0].Device = New-Object VMware.Vim.VirtualCdrom
    $spec.DeviceChange[0].Device.Connectable = New-Object VMware.Vim.VirtualDeviceConnectInfo
    $spec.DeviceChange[0].Device.Connectable.Connected = $false
    $spec.DeviceChange[0].Device.Connectable.AllowGuestControl = $true
    $spec.DeviceChange[0].Device.Connectable.StartConnected = $true
    $spec.DeviceChange[0].Device.Connectable.Status = 'untried'
    $spec.DeviceChange[0].Device.Backing = New-Object VMware.Vim.VirtualCdromIsoBackingInfo
    $spec.DeviceChange[0].Device.Backing.FileName = $isoPath
    $spec.DeviceChange[0].Device.ControllerKey = 15000
    $spec.DeviceChange[0].Device.UnitNumber = 1
    $spec.DeviceChange[0].Device.DeviceInfo = New-Object VMware.Vim.Description
    $spec.DeviceChange[0].Device.DeviceInfo.Summary = $isoPath
    $spec.DeviceChange[0].Device.DeviceInfo.Label = 'CD/DVD drive 1'
    $spec.DeviceChange[0].Device.Key = 16001
    $spec.DeviceChange[0].Operation = 'edit'
    $spec.VirtualNuma = New-Object VMware.Vim.VirtualMachineVirtualNuma
    $_this = Get-View -Id $vmId
    $_this.ReconfigVM_Task($spec)

    ## Give few seconds to task to complete
    Start-Sleep -Seconds 15

    #---------------PowerOnMultiVM_Task---------------
    # Wait for vmtools to be up and running
    write-Host "# Wait for vmtools to be up and running" 
    Start-VM $vmName | Wait-Tools



    #----------------- Executing Upgrade -----------------

    #Prepare Script to run the installation upgarde to Windows Server 2019
    Write-Host "Ready to starting upgrade process on VM :" $vmName
    Write-Host "THIS IS A MANUAL TASK NOW!" -BackgroundColor red
    Write-Host "Please run manually on the vm the c:\upgrade\ powershell script" -BackgroundColor red


    <#
    # This code is intencionally commented out, to avoid full automation on the installation procedure

        #Create Session based on the user/account provided
        #$cred = New-Object System.Management.Automation.PSCredential $guestUser,$guestPassword

        # .\setup.exe /Install /Media /Quiet  /InstallFile "D:\Sources\Install.wim" "/auto" "upgrade" "/pkey" "N69G4-B89J2-4G8F4-WWYCC-J464C" /MediaPath "D:"
        $script = {
            cd c:\\Upgrade;
            echo "cd d:" >> run_this_script_to_upgrade.ps1
            echo '.\setup.exe /Install /Media  /InstallFile "D:\Sources\Install.wim" "/auto" "upgrade" "/pkey" "N69G4-B89J2-4G8F4-WWYCC-J464C" /MediaPath "D:"' >> run_this_script_to_upgrade.ps1
            #.\setup.exe /auto upgrade /quiet /Compat Ignorewarnings /Imageindex 2
            }

        #invoke Scripts in OS
        Invoke-VMScript -VM $vm -ScriptText $script -GuestCredential $cred
    #>

} ## End of Upgrade for all Virtual Machines - Remember to do the MANUAL TASKS
write-host '******************' -backgroundcolor red -foregroundcolor white
write-host 'End of Upgrade for all Virtual Machines - Remember to do the MANUAL TASKS' -backgroundcolor yellow -foregroundcolor red
write-host '******************' -backgroundcolor red -foregroundcolor white