Configuration SRVPullConfig  #Mot clé CONFIGURATION suivi d'un nom pour cette configuration
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration, ComputerManagementDsc #On importe les ressources que l'on va utiliser dans la configuration

    Node "SRV01"
    {
        #region <Script>

        Script "PowershellModule" {
            GetScript  = {
                Return @{ Result = (Get-Module -Name PowershellModule) }
            }
            SetScript  = {
                Install-Module -Name PowershellModule -Scope AllUsers
            }
            TestScript = {
                if (Test-Path "$env:ProgramData\WindowsPowerShell\Modules\PowershellModule") {
                    Return $true
                }
                else {
                    Return $false
                }
            }
        }

        Script "ComputerManagementDsc" {
            GetScript  = {
                Return @{ Result = (Get-Module -Name ComputerManagementDsc) }
            }
            SetScript  = {
                Install-Module -Name ComputerManagementDsc -Scope AllUsers
            }
            TestScript = {
                if (Test-Path "$env:ProgramData\WindowsPowerShell\Modules\ComputerManagementDsc") {
                    Return $true
                }
                else {
                    Return $false
                }
            }
        }

        #endregion <Script>

        #region <Setup Dir>
        File "RepTest" {
            Type            = "Directory"
            DestinationPath = "C:\Test"
            Ensure          = "Present"
        }

        File "RepConfiguration" {
            Type            = "Directory"
            DestinationPath = "C:\Test\Configuration"
            Ensure          = "Present"
            DependsOn       = "[File]RepTest"
        }

        File "RepMOFFiles" {
            Type            = "Directory"
            DestinationPath = "C:\Test\MOFFiles"
            Ensure          = "Present"
            DependsOn       = "[File]RepTest"
        }

        File "RepLCMFiles" {
            Type            = "Directory"
            DestinationPath = "C:\Test\LCMFiles"
            Ensure          = "Present"
            DependsOn       = "[File]RepTest"
        }

        File "RepSources" {
            Type            = "Directory"
            DestinationPath = "C:\Sources"
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
        #endregion <Setup Dir>

        Environment 'MaVariable' {
            Name   = "MaVariable"
            Value  = "MaValeur"
            Ensure = "Present"
            Path   = $false
        }

        Registry 'MyNewKey' {
            Key       = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\MyNewKey"
            ValueName = ''
            Ensure    = "Present"
        }
    }
}


SRVPullConfig -OutputPath ./MOFFiles

#Start-DscConfiguration -Path ./SRVPullConfig -ComputerName SRV01 -Wait -Force -Verbose