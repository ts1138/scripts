<#
 Add Credential Manager Entries for DEV/QA Environments.  Since we use multiple domains, 
 this script prompts for domain username and password and sets up credentials in credential
 manager for all SQL servers.
 
 Tom Seery 7/21/2017
#>

#clear screen
clear

# List of DEV/QA Environments
$bookerenv =@("devxx".."devxxx")

#Prompt for User Name and Password

$user = Read-Host -prompt 'Enter your <domain> username (ex. jsmith)'
$username = "<domain>\" + $user
$password = Read-Host -assecurestring 'Enter your password '

#Decode Password for Credential Manager
$decodedpassword = '"' + [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)) + '"'

#Select to add all environments or just one to Credential Manager
$alldom = Read-Host -Prompt 'Do you want to add all DEV/QA Environments or just one? (all/one)'

if ($alldom -eq 'one')
{
    $environment = Read-Host -prompt 'Enter the Environment (ex. "dev04") '
    $username = "<domain>\" + $user
    $servername = "<domain prefix>" + $environment + ".<domain>.local:1433"
    cmdkey /add:$servername /user:$username /pass:$decodedpassword
}

Else
{
  For ($i=0; $i -lt $bookerenv.Count; $i++){
    $servername = "<domain prefix>" + $bookerenv[$i] + ".<domain>.local:1433"
    cmdkey /add:$servername /user:$username /pass:$decodedpassword
    $servername
    }
}


