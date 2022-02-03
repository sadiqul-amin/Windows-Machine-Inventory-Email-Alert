Set-ExecutionPolicy Unrestricted 

$hostname = hostname 

<#
Function set to grab Computer hardware specs 
 #>
function systeminfo { 
    $output = "" 
    $machine = "."
	
    $compInfo = Get-WmiObject Win32_computersystem -comp $machine
  	$output += "SYSTEM INFORMATION `r`n"
    $output += "===========================================================================`r`n"
    $output += "Hostname :" + $compinfo.name + "`r`n"
	$output += "Model :" + $compinfo.model + "`r`n"

    $biosInfo = Get-WmiObject Win32_bios -comp $machine
	$output += "Manufacturer :" + $biosinfo.Manufacturer + "`r`n"
	$output += "Serial No. :" + $biosinfo.SerialNumber+ "`r`n"
	$output += "BIOS Ver. :" + $biosinfo.Name + "`r`n"
	$output += "SM BIOS Ver:" + $biosinfo.SMBIOSBIOSVersion + "`r`n"
    $output += "`r`n"

    $osinfo += Get-WmiObject Win32_OperatingSystem -comp $machine
    $output += "OS Windows:" + $osinfo.Version + "`r`n"
    $output += "`r`n"

    $cpuinfo += Get-Wmiobject Win32_processor -comp $machine
    $output += "CPU :" + $cpuinfo.name + "`r`n"
    $output += "`r`n"

    $raminfo += Get-WmiObject  Win32_PhysicalMemory -comp $machine
    $output += "RAM Manufacturer :" + $raminfo.Manufacturer + "`r`n"
    $output += "RAM :" + "{0:n2} GB" -f ($compinfo.TotalPhysicalMemory/1gb ) + "`r`n"
    $uutput += "RAM Speed : " + $raminfo.Speed + "`r`n"
    $output += "RAM DIM Slot used :" + $raminfo.DeviceLocator + "`r`n"
    $output += "RAM Part No. :" + $raminfo.PartNumber + "`r`n"
    $output += "`r`n"
    
    $hddinfo += Get-WmiObject Win32_DiskDrive -comp $machine
    $output += "HDD Model :" + $hddinfo.Model + "`r`n"
    $logicalDisk = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" -ComputerName $machine
    foreach($disk in $logicalDisk)
    {
    $diskObj = "" | Select-Object Disk,Size,FreeSpace
    $diskObj.Disk = $disk.DeviceID
    $diskObj.Size = "{0:n0} GB" -f (($disk | Measure-Object -Property Size -Sum).sum/1gb)
    $diskObj.FreeSpace = "{0:n0} GB" -f (($disk | Measure-Object -Property FreeSpace -Sum).sum/1gb)

    $text = "{0}  {1}  Free: {2}" -f $diskObj.Disk,$diskObj.size,$diskObj.Freespace
    $output += $text + "`r`n"
    }
    $output += "`r`n"

    $networkinfo = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter 'ipenabled = "true"'

	$output += "Network Adaptar Make / Model :" + $networkinfo.Description + "`r`n"
    $output += "IPv4 and IPv6:" + $networkinfo.IPAddress + "`r`n"
    $output += "Default Gateway :" + $networkinfo.DefaultIPGateway + "`r`n"
    $output += "Domain :" + $compinfo.domain + "`r`n"
	$networkmac = get-wmiobject -class "Win32_NetworkAdapterConfiguration" | Where{$_.IpEnabled -Match "True"}
	$output += "Ethernet Mac address:" + $networkmac.MacAddress + "`r`n"
	$output += "`r`n"
	return $output
}

<#
 Function set to grab installed application(s) info.
 #>
function appInfo {
	$machine = "."
	$output = ""
	$output += "INSTALLED APPLICATIONS `r`n"
	$output += "===========================================================================`r`n"
	
	foreach($apps in (Get-WmiObject Win32_Product -computername $machine)) {
		$output += $apps.Name + " - " + $apps.Version + "`r`n"
	}
	return $output
}

<#
 Function set to hrab security patch info.
 #>
function hotfix {
	$machine = "."
	$output = ""
	$output += "INSTALLED OS HOTFIX `r`n"
	$output += "===========================================================================`r`n"
	
	foreach($hotfix in (Get-HotFix -computername $machine)) {
		$output += $hotfix.Description + " - " + $hotfix.HotFixID + "`r`n"
	}
	return $output
}

$message = "Here is your computer specifications" + "`r`n"
$hardware = systeminfo
$software = appinfo
$hotfix = hotfix

$finaloutput = $message + "`r`n" + $hardware + "`r`n" + $software + "`r`n" + $hotfix 

write-host $finaloutput

<#
 Modify below by adding your SMTP details
 #>
# /-Email variable config section -------------------------------------/
$from = "<noreply-mdt@yourcompany.co.uk>"
$smptsrv = "10.196.3.106"
$port = 25
$to = "it@yourcompany.com"
$subject = "OS Deployment Update for $hostname"
$body = $finaloutput

# /-Send Email cmdlet -------------------------------------------------/
Send-MailMessage -To $to -From $from -Body $body -Subject $subject -SmtpServer $smptsrv -port $port

Set-ExecutionPolicy Restricted
