#region DC Config ###########################
Set-TimeZone -Name "Eastern Standard Time"
$DomainName = Read-Host "Enter your domain name (in 'domain.local' format)"

$NameElements = $DomainName -Split "\."
If($NameElements.Count -le 1) {Write-Error "Must use an FQDN format for domain name (domain.local)"}

# Build domain name in DN Format
$DNDomainName = ""
$NameElements | ForEach-Object {$DNDomainName += "DC=$_,"}
$DNDomainName = $DNDomainName -Replace ",$"

# Check whether the domain exists
Try {$DomainCheck = Get-ADDomain $DomainName}
Catch {Write-Error "$DomainName domain not found"}

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
    New-ADOrganizationalUnit -Name $OU -Path "$DNDomainName"
}

New-ADOrganizationalUnit -Name "Admins" -Path "OU=People,$DNDomainName"
New-ADOrganizationalUnit -Name "Security" -Path "OU=Groups,$DNDomainName"
New-ADOrganizationalUnit -Name "Application" -Path "OU=Groups,$DNDomainName"
New-ADOrganizationalUnit -Name "File Share" -Path "OU=Groups,$DNDomainName"
New-ADOrganizationalUnit -Name "RBAC" -Path "OU=Groups,$DNDomainName"

#endregion


#region Users ##########################
$SuperSecurePassword = (Read-Host -AsSecureString "AccountPassword")
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
				    -UserPrincipalName "$($User.Name)@$DomainName" `
                    -DisplayName $User.displayname `
                    -AccountPassword $SuperSecurePassword `
                    -Path "OU=Resources,$DNDomainName" `
                    -CannotChangePassword $true -PasswordNeverExpires $true
            }
            "User" {
                New-ADUser -name $User.Name `
                    -SamAccountName $User.Name `
				    -UserPrincipalName "$($User.Name)@$DomainName" `
                    -GivenName $User.first `
                    -Surname $User.last `
                    -DisplayName $User.displayname `
                    -AccountPassword $SuperSecurePassword `
                    -Path "OU=People,$DNDomainName"
            }
            "Admin" {
                New-ADUser -name $User.Name `
                    -SamAccountName $User.Name `
				    -UserPrincipalName "$($User.Name)@$DomainName" `
                    -GivenName $User.first `
                    -Surname $User.last `
                    -DisplayName $User.displayname `
                    -AccountPassword $SuperSecurePassword `
                    -Path "OU=Admins,OU=People,$DNDomainName"
            }
        }

        Set-ADUser $User.Name -Enabled $True
    }
    Catch {
        Write-Error $_
    }
}

#endregion


#region Groups ##########################
#region Groups ##########################
$Groups = @(
    @{
        name = "SEC-ServerAdmins"
        OU = "OU=Security,OU=Groups,$DNDomainName"
        description = "Users with Admin permissions on Servers"
    },
	@{
        name = "SEC-RODCDelegatedAdmins"
        OU = "OU=Security,OU=Groups,$DNDomainName"
        description = "Users with Delegated Admin Permissions on RODCs"
    },
	@{
        name = "FS-DFS-IT-RW"
        OU = "OU=File Share,OU=Groups,$DNDomainName"
        description = "Read/Write on \\$DomainName\IT$"
    },
	@{
        name = "APP-BackupUtil-User"
        OU = "OU=Application,OU=Groups,$DNDomainName"
        description = "Login to BackupUtil"
    },
	@{
        name = "APP-BackupUtil-Admin"
        OU = "OU=Application,OU=Groups,$DNDomainName"
        description = "Admin rights in BackupUtil"
    }
)

ForEach ($Group in $Groups) {
    Try {
        New-ADGroup $Group.Name -SamAccountName $Group.Name -Description $Group.description -GroupCategory Security -GroupScope Global `
            -Path $Group.OU
    } Catch { Write-Error $_ }
}

Add-ADGroupMember "Domain Admins" -Members (Get-ADUser -Filter {samAccountName -like "*-DA"}).SamAccountName
Add-ADGroupMember "SEC-ServerAdmins" -Members (Get-ADUser -Filter {samAccountName -like "*-ADM"}).SamAccountName

#endregion

#region Group Policies ##########################
#Download GPOs and Extract
$Path = "C:\Temp\AZ801Files"
New-Item -Path $Path -ItemType Directory -Force
Invoke-WebRequest "https://github.com/DanZab/az801/archive/refs/tags/v0.1.0.zip" -UseBasicParsing -Outfile "$Path.zip"
Expand-Archive -LiteralPath "$Path.zip" -DestinationPath $Path -Force
$Dir = Get-ChildItem $Path -Directory -Name
$GPODirectory = "$Path\$Dir\Active Directory\GPOs"

$GPOs = @(
    @{
        Name = "Server-Admins"
        OU = "OU=Servers,$DNDomainName"
    },
    @{
        Name = "Domain-RDP"
        OU = "$DNDomainName"
    },
    @{
        Name = "Domain-Firewall"
        OU = "$DNDomainName"
    }
)
ForEach ($GPO in $GPOs) {
    New-GPO -Name $GPO.Name
    Import-GPO -Path $GPODirectory -BackupGpoName $GPO.Name -TargetName $GPO.Name
    New-GPLink -Name $GPO.Name -Target $GPO.OU
}
#endregion