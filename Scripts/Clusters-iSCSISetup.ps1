# This script is intended to be ran from a management server that hosts the
# virtual drives the cluster nodes will connect to.
#
# It requires that the iSCSI server role is installed, you can use this command:
#   Add-WindowsFeature "FS-iSCSITarget-Server"
#

# Set your domain name (FQDN suffix)
$Domain = "dzab.local"

# Get the name of the current server
$iSCSIServer = "$($env:COMPUTERNAME).$Domain"

# Set the Name of the iSCSI target
$TargetName = "iSCSI-P1"

# Set the directory the virtual disks will be created in
$Directory = "C:\Disks"

# Set the name of the disks to be created
$Disks = @(
"$Directory\disk1.VHDX",
"$Directory\disk2.VHDX",
"$Directory\disk3.VHDX"
)

# Enter the name of the nodes you are using in your lab
# These should be FQDNs
$Servers = @(
"CLUS-P1.$Domain",
"CLUS-P2.$Domain"
)

# Configure the iSCSI virtual disks and targets
New-Item -ItemType Directory $Directory -Force
ForEach ($Disk in $Disks) {New-IscsiVirtualDisk $Disk -size 10GB}

$InitiatorsIds = @()
ForEach ($Server in $Servers) { $InitiatorsIds += "IQN:iqn.1991-05.com.microsoft:$($Server.toLower())" }
$TargetObject = New-IscsiServerTarget -TargetName $TargetName -InitiatorIds $InitiatorsIds
ForEach ($Disk in $Disks) { Add-IscsiVirtualDiskTargetMapping -TargetName $TargetName -DevicePath $Disk }


# Configure the Node Servers to connect to the iSCSI drives
$ScriptBlock = {
	Param ($iSCSIServer, $iSCSITargetName, $iSCSITargetPath)
	Start-Service -ServiceName MSiSCSI
	Set-Service -ServiceName MSiSCSI -StartupType Automatic
	Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools
	Install-WindowsFeature -Name "FS-FileServer" -IncludeManagementTools

	New-iSCSITargetPortal -TargetPortalAddress $iSCSIServer
	Connect-iSCSITarget -NodeAddress $iSCSITargetPath
}
Invoke-Command -ComputerName $Servers -ScriptBlock $ScriptBlock -ArgumentList $iSCSIServer, $($TargetObject.TargetName), $($TargetObject.TargetIqn)

# On the first server in the list, initiate the new storage and configure volumes
$ScriptBlock = {
  $Disks = Get-Disk | Where-Object {$_.PartitionStyle -eq 'RAW' -and $null -ne $_.SerialNumber}
  ForEach ($Disk in $Disks) {
    Initialize-Disk -PartitionStyle MBR -Number $Disk.Number
    $Part = New-Partition -DiskNumber $Disk.Number -UseMaximumSize -AssignDriveLetter
    Format-Volume -DriveLetter $Part.DriveLetter -FileSystem NTFS
  }
}
Invoke-Command -ComputerName $Servers[0] -ScriptBlock $ScriptBlock