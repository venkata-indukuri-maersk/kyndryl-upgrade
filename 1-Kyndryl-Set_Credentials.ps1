

#Set the session username and password

$guestUser = 'vra4u\administrator'
$userPassword = 'PASSWORD' 
$guestPassword = ConvertTo-SecureString -String $userPassword -AsPlainText -Force


$vcenterUser = 'administrator@vsphere.local'
$vcenterPassword = 'PASSWORD'


$cred = New-Object System.Management.Automation.PSCredential $guestUser,$guestPassword

clear


#$userCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "myUserName", $userPassword