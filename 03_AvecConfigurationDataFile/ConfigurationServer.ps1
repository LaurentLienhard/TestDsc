Configuration ConfigurationServer {
    param (

        [Parameter(Mandatory = $true)]
        [pscredential]$domainadmin

    )

    Import-DscResource –ModuleName PSDesiredStateConfiguration, chocolatey, ComputerManagementDsc, @{ModuleName = 'xRemoteDesktopSessionHost'; ModuleVersion = "1.8.0.0" }
    Import-DscResource -ModuleName PowerShellGet -ModuleVersion "2.2.5"

    #Configure All Node
    Node $AllNodes.NodeName {

        #Install feature for All Node
        foreach ($Feature in $Node.WindowsFeature) {
            WindowsFeature $Feature {
                Name   = "$Feature"
                Ensure = $Node.Ensure
            }
        }

        #Install services for All Node
        foreach ($Service in $Node.Services) {
            Service $Service {
                Name        = "$Service"
                Ensure      = $Node.Ensure
                StartupType = $Node.ServiceStartupType
                State       = $Node.ServiceState
            }
        }

        #Configure All Pull Server
        if ($Node.Role -contains "PullServer") {
            #Install feature for Pull Server
            foreach ($Feature in $ConfigurationData.Roles.Where{ $_.RoleName -Contains "PullServer" }.WindowsFeature) {
                WindowsFeature $Feature {
                    Name   = "$Feature"
                    Ensure = $Node.Ensure
                }
            }

            #Install module for Pull Server
            foreach ($Module in $ConfigurationData.Roles.Where{ $_.RoleName -Contains "PullServer" }.Modules) {
                PSModule "$Module" {
                    Name   = "$Module"
                    Ensure = $Node.Ensure
                }
            }

            #Install Service for Pull Server
            foreach ($Service in $ConfigurationData.Roles.Where{ $_.RoleName -Contains "PullServer" }.Services) {
                Service $Service {
                    Name        = "$Service"
                    Ensure      = $Node.Ensure
                    StartupType = $Node.ServiceStartupType
                    State       = $Node.ServiceState
                }
            }

            #region <Config Directory>
            File "RepTest" {
                DestinationPath = "C:\Test"
                Ensure          = "Present"
                Type            = "Directory"
            }

            File "RepConfiguration" {
                DestinationPath = "C:\Test\Configuration"
                Ensure          = "Present"
                Type            = "Directory"
                DependsOn       = "[File]RepTest"
            }

            File "RepMOFFiles" {
                DestinationPath = "C:\Test\MOFFiles"
                Ensure          = "Present"
                Type            = "Directory"
                DependsOn       = "[File]RepTest"
            }

            File "RepLCMFiles" {
                DestinationPath = "C:\Test\LCMFiles"
                Ensure          = "Present"
                Type            = "Directory"
                DependsOn       = "[File]RepTest"
            }

            File "RepSources" {
                DestinationPath = "C:\Sources"
                Type            = "Directory"
                Ensure          = "Present"
            }

            SmbShare 'RepSources' {
                Ensure      = "Present"
                Path        = "C:\Sources"
                Name        = "Sources"
                Description = "Sources d'installation"
                FullAccess  = @('Everyone')
                DependsOn   = "[File]RepSources"
            }
            #endregion <Config Directory>
        }

        #Configure All Domain Controller
        if ($Node.Role -contains 'DomainController') {
            foreach ($Feature in $ConfigurationData.Roles.Where{ $_.RoleName -Contains 'DomainController' }.WindowsFeature) {
                WindowsFeature "DC_$Feature" {
                    Name   = "$Feature"
                    Ensure = $Node.Ensure
                }
            }

            #Install services for Domain Controller
            foreach ($Service in $ConfigurationData.Roles.where{ $_.RoleName -Contains 'DomainController' }.Services) {
                Service "DC_$Service" {
                    Name        = "$Service"
                    Ensure      = $Node.Ensure
                    StartupType = $Node.ServiceStartupType
                    State       = $Node.ServiceState
                }
            }
        }

        if ($Node.Role -contains 'Connection Broker') {
            $RDData = $ConfigurationData.RDSData

            foreach ($Feature in $ConfigurationData.Roles.Where{ $_.RoleName -Contains 'Connection Broker' }.WindowsFeature) {
                WindowsFeature "CB_$Feature" {
                    Name   = "$Feature"
                    Ensure = $Node.Ensure
                }
            }

<#             WaitForAll SessionHost {

                NodeName         = 'server2.hiat.local'
                ResourceName     = '[WindowsFeature]RDS_RDS-RD-Server'
                RetryIntervalSec = 15
                RetryCount       = 50
                DependsOn        = '[WindowsFeature]CB_RDS-Licensing'
            } #>

            xRDSessionDeployment "NewDeploy" {
                ConnectionBroker     = $RDData.ConnectionBroker
                SessionHost          = $RDData.SessionHost
                WebAccessServer      = $RDData.WebAccessServer
                PsDscRunAsCredential = $domainadmin
            }

            xRDSessionCollection "MyCollection" {
                CollectionName       = $RDData.CollectionName
                SessionHost          = $RDData.SessionHost
                ConnectionBroker     = $RDData.ConnectionBroker
                DependsOn            = '[xRDSessionDeployment]NewDeploy'
                PsDscRunAsCredential = $domainadmin
            }

            xRDSessionCollectionConfiguration "CollectionConfig" {
                CollectionName               = $RDData.CollectionName
                ConnectionBroker             = $RDData.ConnectionBroker
                AutomaticReconnectionEnabled = $true
                DisconnectedSessionLimitMin  = $RDData.DisconnectedSessionLimitMin
                IdleSessionLimitMin          = $RDData.IdleSessionLimitMin
                BrokenConnectionAction       = $RDData.BrokenConnectionAction
                UserGroup                    = $RDData.UserGroup
                DependsOn                    = '[xRDSessionCollection]MyCollection'
                PsDscRunAsCredential         = $domainadmin
            }

            xRDLicenseConfiguration "licenseconfig" {

                ConnectionBroker = $RDData.ConnectionBroker
                LicenseServer = $RDData.LicenseServer
                LicenseMode          = 'PerUser'
                DependsOn            = '[xRDSessionCollectionConfiguration]CollectionConfig'
                PsDscRunAsCredential = $domainadmin
            }
        }

        if ($Node.Role -Contains 'RdsServer' ) {
            #Install feature for Rds Server
            foreach ($Feature in $ConfigurationData.Roles.Where{ $_.RoleName -Contains 'RdsServer' }.WindowsFeature) {
                WindowsFeature "RDS_$Feature" {
                    Name   = $Feature
                    Ensure = $Node.Ensure
                }
            }

            #region <ChocoPackage>
            #Install Chocolatey on Server RDS
            ChocolateySoftware ChocoInst {
                Ensure                = $Node.Ensure
                InstallationDirectory = $ConfigurationData.ChocoParams.ChocoInstallDir
                ChocoTempDir          = $ConfigurationData.ChocoParams.ChocoTempDir
            }

            #Configure Chocolatey on Server RDS
            ChocolateySource ChocolateyOrg {
                DependsOn = '[ChocolateySoftware]ChocoInst'
                Ensure    = $Node.Ensure
                Name      = 'Chocolatey'
                Source    = $ConfigurationData.ChocoParams.ChocoSource
                Priority  = 0
                Disabled  = $false
            }

            #Install chocolatey package for Server RDS
            foreach ($Package in $ConfigurationData.Roles.where{ $_.RoleName -eq 'RdsServer' }.ChocoPackages) {
                ChocolateyPackage $Package.Name {
                    Name      = $Package.Name
                    Ensure    = $Node.Ensure
                    Version = $Package.Version
                    ChocolateyOptions = $Package.ChocoOptions
                    DependsOn = '[ChocolateySoftware]ChocoInst'
                }
            }
            #endregion <ChocoPackage>
        }
    }
}

ConfigurationServer -ConfigurationData ".\ConfigurationData.psd1" -OutputPath ".\MOFFiles"
<# Get-ChildItem -Path C:\Test\MOF | foreach {
$MofName = $_.Name
$DestinationMof = "C:\Program Files\WindowsPowershell\DSCService\Configuration\$MofName"
Copy-Item $_.FullName $DestinationMof
New-DscChecksum $DestinationMof -force
} #>
#Start-DscConfiguration -Wait -Verbose -Path "C:\Test\Dsc" -Force
#Test-DscConfiguration -Path "C:\Test\Dsc"