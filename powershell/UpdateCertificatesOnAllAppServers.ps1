#Update Wildcard Certificates on All Windows App Servers in Datacenter  #
# Tom Seery 12/13/2017

#Function to Browse for Files
Function Get-OpenFile($initialDirectory)
{ 
[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |
Out-Null

$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.initialDirectory = $initialDirectory
$OpenFileDialog.filter = "All Files (*.*)|*.*|Text files (*.txt)|*.txt|PFX files(*.pfx)|*.pfx"

$OpenFileDialog.ShowDialog() | Out-Null
$OpenFileDialog.filename
$OpenFileDialog.ShowHelp = $true
}

#Prompt for path to Certificate file (.pfx)
$wshell = New-Object -ComObject Wscript.Shell

$wshell.Popup("Browse to Certificate File (PFX)",0,"Open",0x1)

$certpath = Get-OpenFile

#Prompt for path to server file (.txt)
$wshell.Popup("Browse to Servers file with list of servers",0,"Open",0x1)

$serversfile= Get-OpenFile

#Read the list of Servers in the servers text file
$servers = Get-Content $serversfile

#Create a session to each App Server in NJ1
$session = New-PsSession –ComputerName $servers

#Copy the certificate (.PFX) file from your computer to the servers where it will be installed:
$servers | foreach-Object{copy-item -Path $certpath -Destination "\\$_\c$"}

#Run CertUtil to install the Certificate to the Cert Store...add actual PFX password when running
Invoke-command -Session $session {certutil -p <password> -importpfx c:\<name of cert>.pfx}

#The certificate file is then deleted from the remote machine:
$servers | foreach-object {Remove-Item -Path "\\$_\c$\<name of cert>.pfx"}

#Delete Old Certificate
Invoke-command -Session $session {netsh http delete sslcert ipport=0.0.0.0:443}

#Add New Certificate - Change certhash (Thumbprint) when there is a new certificate
Invoke-command -Session $session {netsh http add sslcert ipport=0.0.0.0:443 certhash = ‎<Cert thumbprint> appid='{<appID>}'}