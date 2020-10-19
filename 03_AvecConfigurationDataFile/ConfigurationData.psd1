@{
    AllNodes    = @(
        @{
            NodeName           = "*"
            WindowsFeature     = @("SNMP-Service", "SNMP-WMI-Provider")
            Services           = "SNMP"
            Ensure             = "Present"
            ServiceState       = "Running"
            ServiceStartupType = "Automatic"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser        = $true
        },
        @{
            NodeName = "SRV01"
            Role     = @("PullServer", "DomainController", "RootCA", "Routeur")
        },
        @{
            NodeName = "SERVER1"
            Role     = @("Connection Broker")
        }
        @{
            NodeName = "SERVER2"
            Role     = @("RdsServer")
        }
    )
    Roles       = @(
        @{
            RoleName = "PullServer"
            Modules  = @("PSDesiredStateConfiguration", "chocolatey", "ComputerManagementDsc", "cChoco")
        },
        @{
            RoleName       = "DomainController"
            WindowsFeature = @(
                @{
                    Name = "AD-Domain-Services"
                    Ensure = "Present"
                }
                @{
                    Name = "RSAT-AD-PowerShell"
                    Ensure = "Present"
                }
            )

            Services       = @(
                @{
                    Name = "DNS"
                    Ensure = "Present"
                    ServiceState       = "Running"
                    ServiceStartupType = "Automatic"
                }
                @{
                    Name = "NTDS"
                    Ensure = "Present"
                    ServiceState       = "Running"
                    ServiceStartupType = "Automatic"
                }
                )
        },
        @{
            RoleName = "Connection Broker"
            WindowsFeature = @(
                @{
                    Name = "RDS-Connection-Broker"
                    Ensure = "Present"
                }
                @{
                    Name = "RDS-Licensing"
                    Ensure = "Present"
                }
            )
        }
        @{
            RoleName       = "RdsServer"
            WindowsFeature = @(
                @{
                    Name = "RDS-RD-Server"
                    Ensure = "Present"
                }
                )

            ChocoPackages  = @(
                @{
                    Name = "javaruntime"
                    Version = "8.0.60"
                    Params = ""
                    Ensure  = "present"
                }
                @{
                    Name = "7zip.install"
                    Version = "19.0"
                    Params   = ""
                    Ensure  = "Present"
                 }
                @{
                    Name = "git"
                    Version = "2.28.0"
                    Params  = '--params "/GitAndUnixToolsOnPath /NoGitLfs /SChannel /NoAutoCrlf"'
                    Ensure  = "Present"
                 }
                @{
                    Name    = "microsoft-edge"
                    Version = "85.0.564.68"
                    Ensure  = "Present"
                 }
                @{
                    Name    = "powershell-core"
                    Version = "7.0.3"
                    Params  = '--install-arguments="ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 REGISTER_MANIFEST=1 ENABLE_PSREMOTING=1"'
                    Ensure = "Present"
                 }
            )

            RegistryKeys = @(
                @{
                    Name = "HKEY_LOCAL_MACHINE\SOFTWARE\ExampleKey1"
                    ValueName = "TestValue"
                    ValueData   = "TestData"
                    ValueType = "ExpandString"
                    Ensure = "Present"
                }
            )

            MsiPackages =@(
                @{
                    #Necessaire pour PREM
                    Name      = "Microsoft SOAP Toolkit 3.0"
                    Path = "\\srv01\Sources\Prem\soapsdk.msi"
                    ProductId = "BCB4C18A-ACA6-4383-8688-E19933A705DD"
                    Arguments = "/quiet /qn /norestart"
                    Ensure = "Present"
                }
            )

            Files =@(
                @{
                    Name = "exception.sites"
                    SourcePath = "\\srv01\sources\Sun\Java\Deployment\security\exception.sites"
                    DestinationPath = "C:\Windows\Sun\Java\Deployment\security\exception.sites"
                    Type = "File"
                    MatchSource     = $true
                    Ensure = "Present"
                    checksum        = "modifiedDate"
                }
            )
        }
    )
    ChocoParams = @{
        ChocoInstallDir = "$env:ProgramData\Chocolatey"
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
