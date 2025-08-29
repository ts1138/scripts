#Create multiple DLs from a List and grant a user/group permissions to Modify Membership
#Tom Seery 12-15-2015

#Read DLs from a text file
$DistribLists = Get-Content C:\ListofDistributionLists.txt

#Loop through list of DLs
foreach ($DL in $DistribLists) {

#Create DLs
New-DistributionGroup -Name $DL -OrganizationalUnit "<path to Distribution Group>" -SamAccountName $DL -Type "Distribution"

#Grant user permissions to modify DL Membership
Add-ADPermission -Identity:$DL -User:<user name> -AccessRights ReadProperty, WriteProperty -Properties 'Member'
}
