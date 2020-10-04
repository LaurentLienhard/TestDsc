Configuration ConfigurationServer
{
    Import-DscResource –ModuleName PSDesiredStateConfiguration, chocolatey, ComputerManagementDsc, SqlServerDsc, PowershellModule

    #Configure All Node
    Node $AllNodes.NodeName
    {
        #Install feature for All Node
        Foreach ($Feature in $ConfigurationData.AllNodes.Where{ $_.NodeName -Contains $NodeName }.WindowsFeature) {
            WindowsFeature $Feature {
                Name   = "$Feature"
                Ensure = $ConfigurationData.AllNodes.Where{ $_.NodeName -Contains $NodeName }.Ensure
            }
        }

        #Install services for All Node
        foreach ($Service in $ConfigurationData.AllNodes.where{$_.NodeName -Contains $NodeName}.Services) {
            Service $Service {
                Name        = "$Service"
                Ensure      = $ConfigurationData.AllNodes.Where{ $_.NodeName -Contains $NodeName }.Ensure
                StartupType = $ConfigurationData.AllNodes.Where{ $_.NodeName -Contains $NodeName }.ServiceStartupType
                State       = $ConfigurationData.AllNodes.Where{ $_.NodeName -Contains $NodeName }.ServiceState
            }
        }
    }

    #Configure All Pull Server
    Node $AllNodes.Where{ $_.Role -Contains "PullServer" }.NodeName
    {
        #Install feature for Pull Server
        Foreach ($Feature in $ConfigurationData.Roles.Where{ $Node.Role -Contains $_.RoleName }.WindowsFeature) {
            WindowsFeature $Feature {
                Name   = "$Feature"
                Ensure = $ConfigurationData.AllNodes.Where{ $_.NodeName -Contains $NodeName }.Ensure
            }
        }

        #Install module for Pull Server
        Foreach ($Module in $ConfigurationData.Roles.Where{ $Node.Role -Contains $_.RoleName }.Modules) {
            PSModuleResource "$Module" {
                Module_Name = "$Module"
                Ensure       = $ConfigurationData.AllNodes.Where{ $_.NodeName -Contains $NodeName }.Ensure
                InstallScope = "AllUsers"
            }
        }

        #Install Service for Pull Server
        Foreach ($Service in $ConfigurationData.Roles.Where{ $Node.Role -Contains $_.RoleName }.Services) {
            Service $Service {
                Name        = "$Service"
                Ensure      = $ConfigurationData.AllNodes.Where{ $_.NodeName -Contains $NodeName }.Ensure
                StartupType = $ConfigurationData.AllNodes.Where{ $_.NodeName -Contains $NodeName }.ServiceStartupType
                State       = $ConfigurationData.AllNodes.Where{ $_.NodeName -Contains $NodeName }.ServiceState
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
    Node $AllNodes.Where{ $_.Role -Contains "DomainController" }.NodeName
    {
        #Install feature for Domain Controller
        Foreach ($Feature in $ConfigurationData.Roles.Where{$_.RoleName -Contains $Node.Role}.WindowsFeature)
        {
            WindowsFeature $Feature {
                Name   = "$Feature"
                Ensure      = $ConfigurationData.AllNodes.Where{ $_.NodeName -Contains $NodeName }.Ensure
            }
        }

        #Install services for Domain Controller
        foreach ($Service in $ConfigurationData.Roles.where{ $_.RoleName -Contains $Node.Role }.Services)
        {
            Service $Service
            {
                Name = "$Service"
                Ensure      = $ConfigurationData.AllNodes.Where{ $_.NodeName -Contains $NodeName }.Ensure
                StartupType = $ConfigurationData.AllNodes.Where{ $_.NodeName -Contains $NodeName }.ServiceStartupType
                State       = $ConfigurationData.AllNodes.Where{ $_.NodeName -Contains $NodeName }.ServiceState
            }
        }
    }

    #Configure All Rds Server
    Node $AllNodes.Where{ $_.Role -Contains "RdsServer" }.NodeName
    {
        #Install feature for Rds Server
        Foreach ($Feature in $ConfigurationData.Roles.Where{ $_.RoleName -Contains $Node.Role }.WindowsFeature) {
            WindowsFeature $Feature {
                Name   = "$Feature"
                Ensure = $ConfigurationData.AllNodes.Where{ $_.NodeName -Contains $NodeName }.Ensure
            }
        }

        #region <ChocoPackage>
        #Install Chocolatey on Server RDS
        ChocolateySoftware ChocoInst {
            Ensure                = $ConfigurationData.AllNodes.Where{ $_.NodeName -Contains $NodeName }.Ensure
            InstallationDirectory = $ConfigurationData.ChocoParams.ChocoInstallDir
            ChocoTempDir          = $ConfigurationData.ChocoParams.ChocoSource
        }

        #Configure Chocolatey on Server RDS
        ChocolateySource ChocolateyOrg {
            DependsOn = '[ChocolateySoftware]ChocoInst'
            Ensure    = $ConfigurationData.AllNodes.Where{ $_.NodeName -Contains $NodeName }.Ensure
            Name      = 'Chocolatey'
            Source    = $ConfigurationData.ChocoParams.ChocoTempDir
            Priority  = 0
            Disabled  = $false
        }
        #endregion <ChocoPackage>

    }
}

ConfigurationServer -ConfigurationData ".\ConfigurationData.psd1" -OutputPath ".\MOFFiles"

<# Get-ChildItem -Path C:\Test\MOF | Foreach {
$MofName = $_.Name
$DestinationMof = "C:\Program Files\WindowsPowershell\DSCService\Configuration\$MofName"
Copy-Item $_.FullName $DestinationMof
New-DscChecksum $DestinationMof -force
} #>

#Start-DscConfiguration -Wait -Verbose -Path "C:\Test\Dsc" -Force

#Test-DscConfiguration -Path "C:\Test\Dsc"