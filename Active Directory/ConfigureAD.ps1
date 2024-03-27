#region DC Config ###########################
Set-TimeZone -Name "Eastern Standard Time"
$DomainName = Read-Host "Enter your domain name (in 'DC=domain,DC=local' format)"

#region Firewall ##########################
New-NetFirewallRule -DisplayName "Allow From vNet" -Direction "Inbound" -Action "Allow" -Protocol "Any" -LocalPort "Any" -RemoteAddress "10.0.0.0/16"
#endregion

#endregion
#region Organizational Units ##########################
$OUs = @(
    "Workstations",
    "Servers",
    "People",
    "Groups",
    "Resources"
)

ForEach ($OU in $OUs) {
    New-ADOrganizationalUnit -Name $OU -Path "$DomainName"
}

New-ADOrganizationalUnit -Name "Admins" -Path "OU=People,$DomainName"
New-ADOrganizationalUnit -Name "Security" -Path "OU=Groups,$DomainName"
New-ADOrganizationalUnit -Name "Application" -Path "OU=Groups,$DomainName"
New-ADOrganizationalUnit -Name "File Share" -Path "OU=Groups,$DomainName"
New-ADOrganizationalUnit -Name "RBAC" -Path "OU=Groups,$DomainName"

#endregion

#region DNS Settings ##########################
# Reverse Lookup Zones
Add-DnsServerPrimaryZone -NetworkID "10.0.0.0/24" -ReplicationScope "Forest"
Add-DnsServerPrimaryZone -NetworkID "10.0.1.0/24" -ReplicationScope "Forest"
Add-DnsServerPrimaryZone -NetworkID "10.0.2.0/24" -ReplicationScope "Forest"

#endregion

#region Users ##########################
$SuperSecurePassword = (Read-Host -AsSecureString 'AccountPassword')
$Users = @(
    @{
        name = "svc_adjoin"
        displayname = "svc_adjoin"
        type = "ServiceAcct"
    },
    @{
        name = "LSullivan"
        first = "Liam"
        Last = "Sullivan"
        displayname = "Liam Sullivan"
        type = "User"
    },
    @{
        name = "EWilson"
        first = "Emma"
        Last = "Wilson"
        displayname = "Emma Wilson"
        type = "User"
    },
    @{
        name = "JCarter"
        first = "John"
        Last = "Carter"
        displayname = "John Carter"
        type = "User"
    },
    @{
        name = "MDavis"
        first = "Mary"
        Last = "Davis"
        displayname = "Mary Davis"
        type = "User"
    },
    @{
        name = "DMiller"
        first = "David"
        Last = "Miller"
        displayname = "David Miller"
        type = "User"
    },
    @{
        name = "EThorne"
        first = "Evelyn"
        Last = "Thorne"
        displayname = "Evelyn Thorne"
        type = "User"
    },
    @{
        name = "CBeaumont"
        first = "Charlotte"
        Last = "Beaumont"
        displayname = "Charlie Beaumont"
        type = "User"
    },
    @{
        name = "NGreene"
        first = "Noah"
        Last = "Greene"
        displayname = "Noah Greene"
        type = "User"
    },
    @{
        name = "OWalker"
        first = "Olivia"
        Last = "Walker"
        displayname = "Olivia Walker"
        type = "User"
    },
    @{
        name = "LEvans"
        first = "Lucas"
        Last = "Evans"
        displayname = "Lucas Evans"
        type = "User"
    },
    @{
        name = "LEvans-ADM"
        first = "Lucas"
        Last = "Evans"
        displayname = "(Admin) Luke Evans"
        type = "Admin"
    },
    @{
        name = "LEvans-DA"
        first = "Lucas"
        Last = "Evans"
        displayname = "(DA) Luke Evans"
        type = "Admin"
    },
    @{
        name = "CBeaumont-ADM"
        first = "Charlotte"
        Last = "Beaumont"
        displayname = "(Admin) Charlie Beaumont"
        type = "Admin"
    },
    @{
        name = "NGreene-ADM"
        first = "Noah"
        Last = "Greene"
        displayname = "(Admin) Noah Greene"
        type = "Admin"
    },
    @{
        name = "NGreene-DA"
        first = "Noah"
        Last = "Greene"
        displayname = "(DA) Noah Greene"
        type = "Admin"
    }
)

ForEach ($User in $Users) {
    Try{
        Switch ($User.Type) {
            "ServiceAcct" {
                New-ADUser -name $User.Name `
                    -SamAccountName $User.Name `
				    -UserPrincipalName "$($User.Name)@dzab.local" `
                    -DisplayName $User.displayname `
                    -AccountPassword $SuperSecurePassword `
                    -Path 'OU=Resources,$DomainName' `
                    -CannotChangePassword $true -PasswordNeverExpires $true
            }
            "User" {
                New-ADUser -name $User.Name `
                    -SamAccountName $User.Name `
				    -UserPrincipalName "$($User.Name)@dzab.local" `
                    -GivenName $User.first `
                    -Surname $User.last `
                    -DisplayName $User.displayname `
                    -AccountPassword $SuperSecurePassword `
                    -Path 'OU=People,$DomainName'
            }
            "Admin" {
                New-ADUser -name $User.Name `
                    -SamAccountName $User.Name `
				    -UserPrincipalName "$($User.Name)@dzab.local" `
                    -GivenName $User.first `
                    -Surname $User.last `
                    -DisplayName $User.displayname `
                    -AccountPassword $SuperSecurePassword `
                    -Path 'OU=Admins,OU=People,$DomainName'
                If ($User.Name -like "*_DA") {
                    Add-ADGroupMember "Domain Admins" -Members $User.Name
                }
            }
        }

        Set-ADUser $User.Name -Enabled $True
    }
    Catch {
        Write-Host "$($User.displayName) Already Exists"
    }
}

#endregion


#region Groups ##########################
#region Groups ##########################
$Groups = @(
    @{
        name = "SEC-ServerAdmins"
        OU = "OU=Security,OU=Groups,$DomainName"
        description = "Users with Admin permissions on Servers"
    },
	@{
        name = "SEC-RODCDelegatedAdmins"
        OU = "OU=Security,OU=Groups,$DomainName"
        description = "Users with Delegated Admin Permissions on RODCs"
    },
	@{
        name = "FS-DFS-IT-RW"
        OU = "OU=File Share,OU=Groups,$DomainName"
        description = "Read/Write on \\dzab.local\IT$"
    },
	@{
        name = "APP-BackupUtil-User"
        OU = "OU=Application,OU=Groups,$DomainName"
        description = "Login to BackupUtil"
    },
	@{
        name = "APP-BackupUtil-Admin"
        OU = "OU=Application,OU=Groups,$DomainName"
        description = "Admin rights in BackupUtil"
    }
)

ForEach ($Group in $Groups) {
    Try {
        New-ADGroup $Group.Name -SamAccountName $Group.Name -Description $Group.description -GroupCategory Security -GroupScope Global `
            -Path $Group.OU
    } Catch { Write-Host "Group $($Group.Name) Already Exist" }
}

Add-ADGroupMember "Domain Admins" -Members (Get-ADUser -Filter {samAccountName -like "*-DA"}).SamAccountName
Add-ADGroupMember "SEC-ServerAdmins" -Members (Get-ADUser -Filter {samAccountName -like "*-ADM"}).SamAccountName

#endregion

#region Computers ##########################
# The domain ext specifies the OU so they don't need to be pre-created
# Creating them here will cause the extension to fail
$Servers = @("MGMT-P1", "RODC-P1","WEB-P1","APP-P1")
ForEach ($Server in $Servers) {
    $Check = Get-ADComputer $Server
    If ($Check) {Move-ADObject $Check -TargetPath "OU=Servers,$DomainName"}
}
$Workstations = @("RODC-CLIENT")
ForEach ($Workstation in $Workstations) {
    $Check = Get-ADComputer $Workstation
    If ($Check) {Move-ADObject $Check -TargetPath "OU=Workstations,$DomainName"}
}
#endregion
