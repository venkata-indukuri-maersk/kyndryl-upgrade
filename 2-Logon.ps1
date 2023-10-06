<#
Objective: Created to help on the upgrade in-place project for 'A' team | Maersk Upgrades

Created By: Jose Cavalheri (jose.cavalheri@maersk.com)
Date: 27/09/2023

Main Tasks:
- Enable Jump Server to have the necesaary tools for the automation scripts requirements

Install Tools:
-- RSAT : Used to manage Active Directory Computer objects
-- PowerCLI : Used to manage vCenter & VMs activities
#>

#----------------- Install Tools Once ----------------
#RSAT to manage AD Objects ( Move Computer from one OU to another)
Install-WindowsFeature -Name "RSAT-AD-PowerShell" -IncludeAllSubFeature

#Install PowerCLI Module ( Manage vCenter VMs, such as shutdown, snapshots, etc)
Install-Module VMware.PowerCLI -Scope CurrentUser


#----------------- Connecting to vCenter Environment ----------------
#Disable the CEIP
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false

# Ignore SSL certs	
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

# Connect to Vcenter
Connect-VIServer -Server $vcenterServer -User $vcenterUser -Password $vcenterPassword

#clean console
clear