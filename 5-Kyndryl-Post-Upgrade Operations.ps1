<#
Objective: Created to help on the upgrade in-place project for Kyndrl team | Maersk Upgrades

Created By: Jose Cavalheri (jose.cavalheri@maersk.com
Date: 27/09/2023

Main Tasks:
- Execute the following activities to ensure consistency on all tools and reportings of upgraded virtual machines

-- Move Computer Object from one OU to target OU
-- Unmount ISO from Virtual Machine
-- Install Softwares:  Such as 7-Zip, Chrome, IBM Tools, etc ( any customization)
-- Collect new information from Upgraded OS to shared folder ( easy to compare before and after upgrade)
#>

#----------------- Set variables ----------------

#Virtual Machine Names : Example:  '2016upgrade05','2016upgrade03','2016upgrade06' 
$vmNames = '2016upgrade05','2016upgrade03','2016upgrade06' 

#folder path to save reports
$folderPath =  '\\192.168.1.228\Upgrade'

# Set Target OU
$targetOU = 'OU=2019,OU=Servers,OU=Kyndryl,DC=vra4u,DC=local'

#ISO Path for the Upgrade to be used
$isoPath = '[CLU-LUN001] ISO/en_windows_server_2019_x64_dvd_4cb967d8.iso'


#----------------- Set Modules ----------------
#AD Module
Import-Module ActiveDirectory 

#----------------- Start Process ----------------
# This will trigger an execution to do multiple machines
foreach ($vmName in $vmNames){

    #----------------- Adjust Computer Account in AD ----------------
    #Identify the AD Computer Object
    $adComputer = Get-ADComputer -Identity $vmName

    #move Object to Target OU
    Move-ADObject -Identity $adComputer -TargetPath $targetOU

    #----------------- Start vCenter Jobs ----------------
    #Get Virtual Machine in vCenter / ID
    write-host "#Get Virtual Machine in vCenter / ID"
    $vm = get-vm -Name $vmName
    $vmId = get-vm -Name $vmName | Select-Object Id
    $vmId = $vmId.id


    # Unmount CD-Rom with ISO
    #---------------ReconfigVM_Task---------------
    $spec = New-Object VMware.Vim.VirtualMachineConfigSpec
    $spec.DeviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec[] (1)
    $spec.DeviceChange[0] = New-Object VMware.Vim.VirtualDeviceConfigSpec
    $spec.DeviceChange[0].Device = New-Object VMware.Vim.VirtualCdrom
    $spec.DeviceChange[0].Device.Connectable = New-Object VMware.Vim.VirtualDeviceConnectInfo
    $spec.DeviceChange[0].Device.Connectable.Connected = $false
    $spec.DeviceChange[0].Device.Connectable.AllowGuestControl = $true
    $spec.DeviceChange[0].Device.Connectable.StartConnected = $false
    $spec.DeviceChange[0].Device.Connectable.Status = 'ok'
    $spec.DeviceChange[0].Device.Backing = New-Object VMware.Vim.VirtualCdromRemoteAtapiBackingInfo
    $spec.DeviceChange[0].Device.Backing.DeviceName = ''
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


    #---------------Do Tasks as Post Ops inside OS/V---------------

    # Upgrade Qualys and Other Softwares as example
    write-host "Upgrade Qualys and Other Softwares as example"
    write-host "Executing thing on OS level - Please wait!"
    $script = {
        #Save executables files for installation
        cd c:\\Upgrade;

        #Saving 7-Zip Installation
        Copy-Item \\192.168.1.228\Upgrade\Software\7z2301-x64.msi -Destination c:\Upgrade
        #Executing Installation
        Write-host "Installing 7 Zip as example"
        msiexec.exe /i 7z2301-x64.msi /qn


        #Saving Chrome.exe Installation
        Copy-Item \\192.168.1.228\Upgrade\Software\Chrome.exe -Destination c:\Upgrade
        #Installing Chrome
        Write-host "Installing Chrome as example"
        ./Chrome.exe /silent /install


        <#
           Do multiple lines to install what you need: examples:
            Flexnet Inventory Agent
            IBM End Point Manager Client
            IBM Tivoli Monitoring
            IBM Tivoli Security Compliance Manager Client
            IBM Tivoli Storage Manager Client
            TAD4D Agent
            Mcafee Agent
            Mcafee Virus Scan Enterprise
            OPNet AppInternal
            RES Automation Manager/Blue Wisdom
            Blue Care Monitoring  Portal Agent
            TADDM
            IPSOFT
            Qualys / crowstrike.. etc
        
        #>

        }

    #invoke Scripts in OS
    Invoke-VMScript -VM $vm -ScriptText $script -GuestCredential $cred

    # Get Refreshed Information from VM within OS
    write-host "Add new files for comparisson to shared drive"
    $script = {
        $vmName = hostname;
        $dateExec = get-date -format 'MM-dd-yyyy';
        $folder = 'C:\Upgrade'

        #Add new files to upgrade Folder
        cd c:\\Upgrade;

        #Cleanup old executables files
        del .\7z2301-x64.msi -Confirm:false
        del .\Chrome.exe -Confirm:false

        #Get new OS information.
        Get-ComputerInfo -Property WindowsBuildLabEx,WindowsEditionID | Out-File -FilePath c:\\upgrade\\upgrade-computerinfo.txt;
        systeminfo.exe | Out-File -FilePath c:\\upgrade\\upgrade-systeminfo.txt;
        ipconfig /all | Out-File -FilePath c:\\upgrade\\upgrade-ipconfig.txt;
        Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object LastBootUpTime | Out-File -FilePath c:\\upgrade\\upgrade-uptime.txt;
        Copy-Item -Path "c:\Upgrade\*" -Destination \\192.168.1.228\Upgrade\$dateExec\$vmName -Recurse -Force;

        }

    #invoke Scripts in OS
    Invoke-VMScript -VM $vm -ScriptText $script -GuestCredential $cred

    #Pre-Check completed
    write-host "Post operations Completed for Virtual Machine" $vmName

} ## End of Post Upgrade for all Virtual Machines
write-host '******************' -backgroundcolor red -foregroundcolor white
write-host 'Compare Shared folder files if all VMs upgraded and starts appllication validation!' -backgroundcolor yellow -foregroundcolor red
write-host '******************' -backgroundcolor red -foregroundcolor white



