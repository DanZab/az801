configuration CreateADPDC 
{ 
    param 
    ( 
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Int]$RetryCount = 20,
        [Int]$RetryIntervalSec = 30
    ) 
    
    Import-DscResource -ModuleName xActiveDirectory, xStorage, xNetworking, PSDesiredStateConfiguration, xPendingReboot
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    $Interface = Get-NetAdapter | Where Name -Like "Ethernet*" | Select-Object -First 1
    $InterfaceAlias = $($Interface.Name)
    $DomainRoot = "DC=dzab,DC=local"

    $RootOUs = @(
        "Workstations",
        "Servers",
        "People",
        "Groups",
        "Resources"
    )
    $SubOUs = @(
        @{name="Admins";path="OU=People,$DomainRoot"},
        @{name="Security";path="OU=Groups,$DomainRoot"},
        @{name="Application";path="OU=Groups,$DomainRoot"},
        @{name="File Share";path="OU=Groups,$DomainRoot"},
        @{name="RBAC";path="OU=Groups,$DomainRoot"}
    )
    $Users = @(
        @{name = "LSullivan";first = "Liam";Last = "Sullivan";displayname = "Liam Sullivan"},
        @{name = "EWilson";first = "Emma";Last = "Wilson";displayname = "Emma Wilson"},
        @{name = "JCarter";first = "John";Last = "Carter";displayname = "John Carter"},
        @{name = "MDavis";first = "Mary";Last = "Davis";displayname = "Mary Davis"},
        @{name = "DMiller";first = "David";Last = "Miller";displayname = "David Miller"},
        @{name = "EThorne";first = "Evelyn";Last = "Thorne";displayname = "Evelyn Thorne"},
        @{name = "CBeaumont";first = "Charlotte";Last = "Beaumont";displayname = "Charlie Beaumont"},
        @{name = "NGreene";first = "Noah";Last = "Greene";displayname = "Noah Greene"},
        @{name = "OWalker";first = "Olivia";Last = "Walker";displayname = "Olivia Walker"},
        @{name = "LEvans";first = "Lucas";Last = "Evans";displayname = "Lucas Evans"}
    )
    $AdminUsers = @(
        @{name = "LEvans-ADM";first = "Lucas";Last = "Evans";displayname = "(Admin) Luke Evans"},
        @{name = "LEvans-DA";first = "Lucas";Last = "Evans";displayname = "(DA) Luke Evans"},
        @{name = "CBeaumont-ADM";first = "Charlotte";Last = "Beaumont";displayname = "(Admin) Charlie Beaumont"},
        @{name = "NGreene-ADM";first = "Noah";Last = "Greene";displayname = "(Admin) Noah Greene"},
        @{name = "NGreene-DA";first = "Noah";Last = "Greene";displayname = "(DA) Noah Greene"}
    )
    $Groups = @(
        @{name = "SEC-ServerAdmins";OU = "OU=Security,OU=Groups,DC=dzab,DC=local";description = "Users with Admin permissions on Servers";members = ($AdminUsers | Where-Object {$_.name -like "*-ADM"}).name},
        @{name = "SEC-RODCDelegatedAdmins";OU = "OU=Security,OU=Groups,DC=dzab,DC=local";description = "Users with Delegated Admin Permissions on RODCs";members = @()},
        @{name = "FS-DFS-IT-RW";OU = "OU=File Share,OU=Groups,DC=dzab,DC=local";description = "Read/Write on \\dzab.local\IT$";members = @()},
        @{name = "APP-BackupUtil-User";OU = "OU=Application,OU=Groups,DC=dzab,DC=local";description = "Login to BackupUtil";members = @()},
        @{name = "APP-BackupUtil-Admin";OU = "OU=Application,OU=Groups,DC=dzab,DC=local";description = "Admin rights in BackupUtil";members = @()}
    )
    [array]$DomainAdmins = ($AdminUsers | Where-Object {$_.name -like "*-DA"}).name
    $DomainAdmins += "dzabinski-da"

    Node localhost
    {
        LocalConfigurationManager {
            RebootNodeIfNeeded = $true
        }

        WindowsFeature DNS { 
            Ensure = "Present" 
            Name   = "DNS"		
        }

        Script GuestAgent
        {
            SetScript  = {
                Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\WindowsAzureGuestAgent' -Name DependOnService -Type MultiString -Value DNS
                Write-Verbose -Verbose "GuestAgent depends on DNS"
            }
            GetScript  = { @{} }
            TestScript = { $false }
            DependsOn  = "[WindowsFeature]DNS"
        }
        
        Script EnableDNSDiags {
            SetScript  = { 
                Set-DnsServerDiagnostics -All $true
                Write-Verbose -Verbose "Enabling DNS client diagnostics" 
            }
            GetScript  = { @{} }
            TestScript = { $false }
            DependsOn  = "[WindowsFeature]DNS"
        }

        WindowsFeature DnsTools {
            Ensure    = "Present"
            Name      = "RSAT-DNS-Server"
            DependsOn = "[WindowsFeature]DNS"
        }

        xDnsServerAddress DnsServerAddress 
        { 
            Address        = '127.0.0.1' 
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = 'IPv4'
            DependsOn      = "[WindowsFeature]DNS"
        }

        xWaitforDisk Disk2
        {
            DiskNumber = 2
            RetryIntervalSec =$RetryIntervalSec
            RetryCount = $RetryCount
        }

        xDisk ADDataDisk 
        {
            DiskNumber  = 2
            DriveLetter = "F"
            DependsOn   = "[xWaitForDisk]Disk2"
        }

        WindowsFeature ADDSInstall { 
            Ensure    = "Present" 
            Name      = "AD-Domain-Services"
            DependsOn = "[WindowsFeature]DNS" 
        } 

        WindowsFeature ADDSTools {
            Ensure    = "Present"
            Name      = "RSAT-ADDS-Tools"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        WindowsFeature ADAdminCenter {
            Ensure    = "Present"
            Name      = "RSAT-AD-AdminCenter"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }
         
        xADDomain FirstDS 
        {
            DomainName                    = $DomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath                  = "F:\NTDS"
            LogPath                       = "F:\NTDS"
            SysvolPath                    = "F:\SYSVOL"
            DependsOn                     = @("[xDisk]ADDataDisk", "[WindowsFeature]ADDSInstall")
        }

        xWaitForADDomain DscForestWait
        {
            DomainName           = $DomainName
            DomainUserCredential = $DomainCreds
            RetryCount           = "3"
            RetryIntervalSec     = "300"
            DependsOn            = "[xADDomain]FirstDS"
        }

        ForEach ($RootOU in $RootOUs)
        {
            xADOrganizationalUnit ($RootOU).Replace(" ","")
            {
                Name                            = $RootOU
                Path                            = $DomainRoot
                ProtectedFromAccidentalDeletion = $true
                Ensure                          = "Present"
                Credential                      = $DomainCreds
                DependsOn                       = @("[xWaitForADDomain]DscForestWait")
            }
        }
        
        ForEach ($SubOU in $SubOUs)
        {
            xADOrganizationalUnit ($SubOU.name).Replace(" ","")
            {
                Name                            = $SubOU.name
                Path                            = $SubOU.path
                ProtectedFromAccidentalDeletion = $true
                Ensure                          = "Present"
                Credential                      = $DomainCreds
                DependsOn                       = @("[xWaitForADDomain]DscForestWait","[xADOrganizationalUnit]$($RootOUs[-1])")
            }
        }
        
        ForEach ($User in $Users)
        {
            xADUser $User.name
            {
                DomainName                    = $DomainName
                Ensure                        = "Present"
                DomainAdministratorCredential = $DomainCreds
                DependsOn                     = "[xADOrganizationalUnit]People"
                UserName                      = $User.name
                Path                          = "OU=People,$DomainRoot"
                Password                      = $Admincreds
                DisplayName                   = $User.displayname
                GivenName                     = $User.first
                Surname                       = $User.last
            }
        }

        ForEach ($AdminUser in $AdminUsers)
        {
            xADUser $AdminUser.name
            {
                DomainName                    = $DomainName
                Ensure                        = "Present"
                DomainAdministratorCredential = $DomainCreds
                DependsOn                     = "[xADOrganizationalUnit]Admins"
                UserName                      = $AdminUser.name
                Path                          = "OU=Admins,OU=People,$DomainRoot"
                Password                      = $Admincreds
                DisplayName                   = $AdminUser.displayname
                GivenName                     = $AdminUser.first
                Surname                       = $AdminUser.last
            }
        }

        xADUser DZabinskiDA
        {
            DomainName                    = $DomainName
            Ensure                        = "Present"
            DomainAdministratorCredential = $DomainCreds
            DependsOn                     = "[xADOrganizationalUnit]Admins"
            UserName                      = "DZabinski-DA"
            Path                          = "OU=Admins,OU=People,$DomainRoot"
        }

        ForEach ($Group in $Groups)
        {
            xADGroup $Group.name
            {
                Ensure      = "Present"
                Credential  = $DomainCreds
                DependsOn   = @("[xWaitForADDomain]DscForestWait","[xADUser]$($AdminUsers[-1].name)")
                GroupName   = $Group.name
                Path        = $Group.OU
                Description = $Group.description
                Members     = $Group.members
            }
        }

        xADGroup DomainAdmins
        {
            Ensure      = "Present"
            Credential  = $DomainCreds
            DependsOn   = @("[xWaitForADDomain]DscForestWait","[xADUser]$($AdminUsers[-1].name)")
            GroupName   = "Domain Admins"
            Members     = $DomainAdmins
        }
    }
}