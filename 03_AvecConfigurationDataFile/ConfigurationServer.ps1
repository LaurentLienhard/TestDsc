Configuration ConfigurationServer {
    Import-DscResource –ModuleName PSDesiredStateConfiguration, chocolatey, ComputerManagementDsc
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