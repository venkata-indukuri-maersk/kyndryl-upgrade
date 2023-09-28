#Prepare the jump Server with required tools

#RSAT to manage AD Objects ( Move Computer from 1 OU to another)
#Install-WindowsFeature -Name "RSAT-AD-PowerShell" -IncludeAllSubFeature

#Install PowerCLI Module ( Manage vCenter VMs, such as shutdown, snapshots, etc)
#Install-Module VMware.PowerCLI -Scope CurrentUser




#Disable the CEIP
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false

# Ignore SSL certs	
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

# Connect to Vcenter
Connect-VIServer -Server vcsa.vra4u.local -User $vcenterUser -Password $vcenterPassword


#Install RSAT on management server
#Get-WindowsCapability -Name RSAT* -Online | Select-Object -Property DisplayName, State

clear