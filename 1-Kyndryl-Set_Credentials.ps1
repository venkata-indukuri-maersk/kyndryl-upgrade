<#
Objective: Created to help on the upgrade in-place project for Kyndrl team | Maersk Upgrades

Created By: Jose Cavalheri (jose.cavalheri@maersk.com)
Date: 27/09/2023

Main Tasks:
- Set variables for the scripts containing the credentials for the VMs and vCenter.
#>

#----------------- Set variables ----------------

#Set the session username and password for VMs
$guestUser = 'domain\username'
$userPassword = 'PASSWORD' 
$guestPassword = ConvertTo-SecureString -String $userPassword -AsPlainText -Force

#Set the session username and password for vCenter
$vcenterUser = 'username@domain'
$vcenterPassword = 'PASSWORD'
$vcenterServer = 'vcsa.vra4u.local'

#Set the PS session credentials
$cred = New-Object System.Management.Automation.PSCredential $guestUser,$guestPassword

#Clear console
clear