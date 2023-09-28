<#
Objective: Created to help on the upgrade in-place project for Kyndrl team | Maersk Upgrades

Created By: Jose Cavalheri (jose.cavalheri@maersk.com)
Date: 27/09/2023

Main Tasks:
- Execute pre-requisite checks on windows server 2012/2016/2019 virtual machines

-- Create a folder on shared folder based on date and hostname
-- Execute fewer scripts to collect data from OS via VMware Tools
-- Requires user and password for execution (access to OS)
-- No downtime required / No impact on current Production VM
#>

#----------------- Set variables ----------------

#Virtual Machine Names : Example:  '2016upgrade05','2016upgrade03','2016upgrade06' 
$vmNames = '2016upgrade02','2016upgrade03','2016upgrade07'

# This will trigger an execution to do multiple machines
foreach ($vmName in $vmNames){

    #folder path to save reports
    $folderPath =  '\\192.168.1.228\Upgrade'

    #----------------- Start code ----------------
    #Get Virtual Machine in vCenter / ID
    $vm = get-vm -Name $vmName
    $vmId = $vmId.id

    #----------------- Executing Pre-Upgrade -----------------
    #Create Session based on the user/account provided
    $cred = New-Object System.Management.Automation.PSCredential $guestUser,$guestPassword


    #Prepare Share Folder to receive information
    write-host "Prepare Share Folder to receive information"
    #Create Folder on Share Drive
    $dateExec = get-date -format 'MM-dd-yyyy'
    md $folderPath\$dateExec\$vmName

    # Get Information from VM within OS
    write-host "Get Information from VM within OS"
    $script = {
        $vmName = hostname;
        $dateExec = get-date -format 'MM-dd-yyyy';
        # Cleanup old Upgrade Folders
        $folder = 'C:\Upgrade'
        if (Test-Path -Path $folder){
            rmdir C:\Upgrade -Recurse -Force   
        }
        #Create new folders
        md c:\\Upgrade;
        Get-ComputerInfo -Property WindowsBuildLabEx,WindowsEditionID | Out-File -FilePath c:\\upgrade\\computerinfo.txt;
        systeminfo.exe | Out-File -FilePath c:\\upgrade\\systeminfo.txt;
        ipconfig /all | Out-File -FilePath c:\\upgrade\\ipconfig.txt;
        Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object LastBootUpTime | Out-File -FilePath c:\\upgrade\\uptime.txt;
        Copy-Item -Path "c:\Upgrade\*" -Destination \\192.168.1.228\Upgrade\$dateExec\$vmName -Recurse -Force;

        #Create the ps1 file for facilitate on execution of upgrade
        cd c:\\Upgrade;
        echo "cd d:" >> run_this_script_to_upgrade.ps1
        # The current key is a generic Microsoft Volume Key (public usage)
        echo '.\setup.exe /Install /Media  /InstallFile "D:\Sources\Install.wim" "/auto" "upgrade" "/pkey" "N69G4-B89J2-4G8F4-WWYCC-J464C" /MediaPath "D:"' >> run_this_script_to_upgrade.ps1
        #.\setup.exe /auto upgrade /quiet /Compat Ignorewarnings /Imageindex 2
        }

    #invoke Scripts in OS
    Invoke-VMScript -VM $vm -ScriptText $script -GuestCredential $cred

    #Pre-Check completed
    write-host "Pre-Check completed. Check for output shared folder & files extracted from virtual machine"

} ## End of Execution for each vm.

