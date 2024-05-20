# Install Server RSAT Tools
Set-TimeZone -Name "Eastern Standard Time"

$RSATs = @(
"RSAT-AD-Tools",
"RSAT-ADRMS",
"RSAT-DNS-Server",
"RSAT-SMS",
"RSAT-Clustering",
"RSAT-Feature-Tools-BitLocker",
"RSAT-Hyper-V-Tools",
"RSAT-File-Services",
"FS-FileServer",
"FS-iSCSITarget-Server"
)
Write-Host "Installing Group Policy Management"
Add-WindowsFeature GPMC
ForEach ($RSAT in $RSATs) {
	Write-Host "Installing $RSAT"
	$Feat = Add-WindowsFeature $RSAT -IncludeAllSubFeature
	Write-Host "$($Feat.ExitCode) - $($Feat.FeatureResult)"
}