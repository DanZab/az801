# These lines install the File Server role with a static IP and use available Cluster Disks
# If you're setting this up in Azure, you have to install it via powershell to assign it an IP
# or you wont be able to connect to it.

# Input the name of your cluster
$ClusterName = "CLUSTER"

# Set the IP you want to assign to the File Server Role
$FSAddress = "10.0.1.100"
$ClusterDisks = (Get-ClusterResource -Cluster $ClusterName | Where {$_.ResourceType -eq "Physical Disk" -and $_.OwnerGroup -like "Available*"}).Name
Add-ClusterFileServerRole -Cluster $ClusterName -Storage $ClusterDisks -Name "FILES" -StaticAddress $FSAddress


# These lines should be run from the Owner Node of the FS Role and allow the Azure ILB Heart Monitor traffic:

# Define variables
$ClusterNetworkName = (Get-ClusterNetwork).Name 
# the cluster network name (Use Get-ClusterNetwork on Windows Server 2012 of higher to find the name)
$IPResourceName = (Get-ClusterResource | Where-Object ResourceType -eq "IP Address").name
# the IP Address resource name 
$ILBIP = “10.0.1.100” 
# the IP Address of the Internal Load Balancer (ILB)
Import-Module FailoverClusters
# If you are using Windows Server 2012 or higher:
Get-ClusterResource $IPResourceName | Set-ClusterParameter -Multiple @{Address=$ILBIP;ProbePort=59999;SubnetMask="255.255.255.255";Network=$ClusterNetworkName;EnableDhcp=0}

# You must disable the Windows Firewall for the Azure Load Balancer heartbeat to work (or allow it specifically)