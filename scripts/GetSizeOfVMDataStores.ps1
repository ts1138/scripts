#Script to generate report of VM DataStore Sizes
#Tom Seery 6-22-2014

if(!(Get-PSSnapin VMWare.Vimautomation.Core -ErrorAction SilentlyContinue)){
    Add-PSSnapin VMWare.Vimautomation.Core
} 

#Connect to VCenter Server
Connect-VIServer <vcenter name>

#Calculate Size of Datastores and report on Capacity, Free Space and Used Space
Get-Datastore | Select-Object Name, Datacenter, @{label='Capacity(GB)';expression={"{0:N2}" -f ($_.CapacityMB / 1024)}}, @{label='Free(GB)';expression={"{0:N2}" -f ($_.FreeSpaceMB / 1024)}}, @{label='Used(GB)';expression={"{0:N2}" -f (($_.CapacityMB - $_.FreeSpaceMB) / 1024)}} | ogv