﻿@{
    AllNodes    = @(
        @{
            NodeName           = "*"
            WindowsFeature     = @("SNMP-Service", "SNMP-WMI-Provider")
            Services           = "SNMP"
            Ensure             = "Present"
            ServiceState       = "Running"
            ServiceStartupType = "Automatic"
        },
        @{
            NodeName = "SRV01"
            Role     = @("PullServer", "DomainController", "RootCA", "Routeur")
        },
        @{
            NodeName = "SERVER1"
            Role     = @("RdsServer")
        }
        @{
            NodeName = "SERVER2"
            Role     = @("RdsServer")
        }
    )
    Roles       = @(
        @{
            RoleName = "PullServer"
            Modules  = @("PSDesiredStateConfiguration", "chocolatey", "ComputerManagementDsc", "SqlServerDsc", "ActiveDirectoryDsc")
        },
        @{
            RoleName       = "DomainController"
            WindowsFeature = @("AD-Domain-Services", "RSAT-AD-PowerShell")
            Services       = @("DNS", "NTDS")
        },
        @{
            RoleName       = "RdsServer"
            WindowsFeature = @("RDS-RD-Server")
            ChocoPackages  = @(
                @{
                    Name = "javaruntime"
                    Version = "8.0.60"
                    Params = ""
                }
                @{
                    Name = "7zip.install"
                    Version = "19.0"
                    Params   = ""
                 }
                @{
                    Name = "git"
                    Version = "2.28.0"
                    ChocoOptions   = @{ PackageParameters = '/GitAndUnixToolsOnPath /NoGitLfs /SChannel /NoAutoCrlf' }
                 }
            )
        }
    )
    ChocoParams = @{
        ChocoInstallDir = "$env:ProgramData\Chocolatey"
        ChocoTempDir    = "C:\temp\Chocolatey"
        ChocoSource     = 'https://chocolatey.org/api/v2'
    }
    LCMParams = @{
        LCMConfigurationMode = 'ApplyAndAutoCorrect'
        LCMActionAfterReboot   = 'ContinueConfiguration'
        LCMRefreshMode     = 'Pull'
        LCMRefreshFrequencyMins = 30
        LCMConfigurationModeFrequencyMins = 15
        LCMRebootNodeIfNeeded = $true
        LCMAllowModuleOverwrite = $true
        LCMServerUrl = "https://SRV01:8080/PSDSCPullServer.svc"
    }
}
