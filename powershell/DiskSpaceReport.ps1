#Calculates Disk Space for servers that are added to serverdiskspace.txt file and emails report.  Run as a daily scheduled task.
#Tom Seery 3-12-2014

# HTML file that will be emailed
$freeSpaceFileName = "C:\Scripts\DiskSpaceReport\FreeSpace.htm"

#Read List of servers
$serverlist = "C:\Scripts\DiskSpaceReport\ServerDiskSpace.txt"

#Alert Levels
$warning = 25
$critical = 10

# Create new HTML file that will be emailed
New-Item -ItemType file $freeSpaceFileName -Force

#Function to format report
Function writeHtmlHeader
{
param($fileName)
$date = ( get-date ).ToString('MM/dd/yyyy')
Add-Content $fileName "<html>"
Add-Content $fileName "<head>"
Add-Content $fileName "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>"
Add-Content $fileName '<title>GLG DiskSpace Report</title>'
Add-Content $fileName '<STYLE TYPE="text/css">'
Add-Content $fileName  "<!--"
Add-Content $fileName  "td {"
Add-Content $fileName  "font-family: Tahoma;"
Add-Content $fileName  "font-size: 11px;"
Add-Content $fileName  "border-top: 1px solid #999999;"
Add-Content $fileName  "border-right: 1px solid #999999;"
Add-Content $fileName  "border-bottom: 1px solid #999999;"
Add-Content $fileName  "border-left: 1px solid #999999;"
Add-Content $fileName  "padding-top: 0px;"
Add-Content $fileName  "padding-right: 0px;"
Add-Content $fileName  "padding-bottom: 0px;"
Add-Content $fileName  "padding-left: 0px;"
Add-Content $fileName  "}"
Add-Content $fileName  "body {"
Add-Content $fileName  "margin-left: 5px;"
Add-Content $fileName  "margin-top: 5px;"
Add-Content $fileName  "margin-right: 0px;"
Add-Content $fileName  "margin-bottom: 10px;"
Add-Content $fileName  ""
Add-Content $fileName  "table {"
Add-Content $fileName  "border: thin solid #000000;"
Add-Content $fileName  "}"
Add-Content $fileName  "-->"
Add-Content $fileName  "</style>"
Add-Content $fileName "</head>"
Add-Content $fileName "<body>"
Add-Content $fileName  "<table width='100%'>"
Add-Content $fileName  "<tr bgcolor='#CCCCCC'>"
Add-Content $fileName  "<td colspan='7' height='25' align='center'>"
Add-Content $fileName  "<font face='tahoma' color='#003399' size='4'><strong>Gerson Lehrman Group DiskSpace Report - $date</strong></font>"
Add-Content $fileName  "</td>"
Add-Content $fileName  "</tr>"
Add-Content $fileName  "</table>"

}

# Function to write the Header to the file
Function writeTableHeader
{
param($fileName)

Add-Content $fileName "<tr bgcolor=#CCCCCC>"
Add-Content $fileName "<td width='10%' align='center'>Drive</td>"
Add-Content $fileName "<td width='50%' align='center'>Drive Label</td>"
Add-Content $fileName "<td width='10%' align='center'>Total Capacity(GB)</td>"
Add-Content $fileName "<td width='10%' align='center'>Used Capacity(GB)</td>"
Add-Content $fileName "<td width='10%' align='center'>Free Space(GB)</td>"
Add-Content $fileName "<td width='10%' align='center'>Freespace %</td>"
Add-Content $fileName "</tr>"
}

Function writeHtmlFooter
{
param($fileName)

Add-Content $fileName "</body>"
Add-Content $fileName "</html>"
}

# Function to calculate disk space parameters and color code free space
Function writeDiskInfo
{
param($fileName,$devId,$volName,$frSpace,$totSpace)
$totSpace=[math]::Round(($totSpace/1073741824),2)
$frSpace=[Math]::Round(($frSpace/1073741824),2)
$usedSpace = $totSpace - $frspace
$usedSpace=[Math]::Round($usedSpace,2)
$freePercent = ($frspace/$totSpace)*100
$freePercent = [Math]::Round($freePercent,0)
 if ($freePercent -gt $warning)
 {
 Add-Content $fileName "<tr>"
 Add-Content $fileName "<td>$devid</td>"
 Add-Content $fileName "<td>$volName</td>"

 Add-Content $fileName "<td>$totSpace</td>"
 Add-Content $fileName "<td>$usedSpace</td>"
 Add-Content $fileName "<td>$frSpace</td>"
 Add-Content $fileName "<td>$freePercent</td>"
 Add-Content $fileName "</tr>"
 }
 elseif ($freePercent -le $critical)
 {
 Add-Content $fileName "<tr>"
 Add-Content $fileName "<td>$devid</td>"
 Add-Content $fileName "<td>$volName</td>"
 Add-Content $fileName "<td>$totSpace</td>"
 Add-Content $fileName "<td>$usedSpace</td>"
 Add-Content $fileName "<td>$frSpace</td>"
 Add-Content $fileName "<td bgcolor='#FF0000' align=center>$freePercent</td>"
 Add-Content $fileName "</tr>"
 }
 else
 {
 Add-Content $fileName "<tr>"
 Add-Content $fileName "<td>$devid</td>"
 Add-Content $fileName "<td>$volName</td>"
 Add-Content $fileName "<td>$totSpace</td>"
 Add-Content $fileName "<td>$usedSpace</td>"
 Add-Content $fileName "<td>$frSpace</td>"
 Add-Content $fileName "<td bgcolor='#FBB917' align=center>$freePercent</td>"
 Add-Content $fileName "</tr>"
 }
}

#Function to create e-mail message
Function sendEmail
{ param($from,$to,$subject,$smtphost,$htmlFileName)
$body = Get-Content $htmlFileName
$smtp= New-Object System.Net.Mail.SmtpClient $smtphost
$msg = New-Object System.Net.Mail.MailMessage $from, $to, $subject, $body
$msg.isBodyhtml = $true
$smtp.send($msg)

}

#Write to HTM file
writeHtmlHeader $freeSpaceFileName
foreach ($server in Get-Content $serverlist)
{
 Add-Content $freeSpaceFileName "<table width='100%'><tbody>"
 Add-Content $freeSpaceFileName "<tr bgcolor='#CCCCCC'>"
 Add-Content $freeSpaceFileName "<td width='100%' align='center' colSpan=6><font face='tahoma' color='#003399' size='2'><strong> $server </strong></font></td>"
 Add-Content $freeSpaceFileName "</tr>"

 writeTableHeader $freeSpaceFileName
 
 #Get storage information using WMI
 $dp = Get-WmiObject win32_logicaldisk -ComputerName $server |  Where-Object {$_.drivetype -eq 3}
 foreach ($item in $dp)
 {
 Write-Host  $item.DeviceID  $item.VolumeName $item.FreeSpace $item.Size
 writeDiskInfo $freeSpaceFileName $item.DeviceID $item.VolumeName $item.FreeSpace $item.Size

 }
Add-Content $freeSpaceFileName "</table>"
}

writeHtmlFooter $freeSpaceFileName

#Set Date for Report
$date = ( get-date ).ToString('yyyy/MM/dd')

#Set Recipients
$Recipients = "<recipient email addresses"

#Send Email message
sendEmail <sender address> $Recipients "Disk Space Report - $Date" <smtp server name> $freeSpaceFileName
