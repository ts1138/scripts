#Script to Prepare and copy SQL files from one folder to another to swap drives.
#Tom Seery 12-1-2015

# Create Folders
New-Item R:\SQL\Data -type directory
New-Item R:\SQL\Logs -type directory

#Copy Permissions

Get-Acl -Path 'E:\SQL\Data' | Set-Acl -Path 'R:\SQL\Data'
Get-Acl -Path 'E:\SQL\Logs' | Set-Acl -Path 'R:\SQL\Logs'
