configuration CreateADPDC 
{ 
    param 
    ( 
        [Parameter(Mandatory)]
        [String]$DomainName,
        
        [Parameter(Mandatory)]
        [String]$DomainDN,

        [Parameter(Mandatory=$false)]
        [String]$GPORepo="https://github.com/DanZab/az801/archive/refs/tags/v0.1.0.zip",
        
        [Parameter(Mandatory=$false)]
        [String]$GPODirector="Active Directory/GPOs",

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Int]$RetryCount = 20,
        [Int]$RetryIntervalSec = 30
    ) 
    
    Import-DscResource -ModuleName xActiveDirectory, xStorage, xNetworking, PSDesiredStateConfiguration, xPendingReboot
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    $Interface = Get-NetAdapter | Where Name -Like "Ethernet*" | Select-Object -First 1
    $InterfaceAlias = $($Interface.Name)
    $DomainRoot = $DomainDN

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
        @{name = "SEC-ServerAdmins";OU = "OU=Security,OU=Groups,$DomainRoot";description = "Users with Admin permissions on Servers";members = ($AdminUsers | Where-Object {$_.name -like "*-ADM"}).name},
        @{name = "SEC-RODCDelegatedAdmins";OU = "OU=Security,OU=Groups,$DomainRoot";description = "Users with Delegated Admin Permissions on RODCs";members = @()},
        @{name = "FS-DFS-IT-RW";OU = "OU=File Share,OU=Groups,$DomainRoot";description = "Read/Write on \\$DomainName\IT$";members = @()},
        @{name = "APP-BackupUtil-User";OU = "OU=Application,OU=Groups,$DomainRoot";description = "Login to BackupUtil";members = @()},
        @{name = "APP-BackupUtil-Admin";OU = "OU=Application,OU=Groups,$DomainRoot";description = "Admin rights in BackupUtil";members = @()}
    )
    [array]$DomainAdmins = ($AdminUsers | Where-Object {$_.name -like "*-DA"}).name
    $DomainAdmins += $Admincreds.UserName

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

        xADUser AdminUser
        {
            DomainName                    = $DomainName
            Ensure                        = "Present"
            DomainAdministratorCredential = $DomainCreds
            DependsOn                     = "[xADOrganizationalUnit]Admins"
            UserName                      = "$($Admincreds.UserName)"
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

        Script GPOs
        {
            SetScript  = {
                $Path = "C:\Temp\AZ801Files"
                New-Item -Path $Path -ItemType Directory -Force
                Invoke-WebRequest "$using:GPORepo" -UseBasicParsing -Outfile "$Path.zip"
                Expand-Archive -LiteralPath "$Path.zip" -DestinationPath $Path -Force
                $Dir = Get-ChildItem $Path -Directory -Name
                $GPODirectory = "$Path\$Dir\$using:GPODirectory"

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
            }
            GetScript  = { @{} }
            TestScript = { $false }
            DependsOn  = @("[xWaitForADDomain]DscForestWait","[xADOrganizationalUnit]$($RootOUs[-1])")
        }
    }
}