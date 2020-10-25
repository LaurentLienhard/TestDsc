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
            Role     = @("PullServer", "DomainController", "RootCA", "Routeur","DNS","DHCP")
        },
        @{
            NodeName = "SERVER1"
            Role     = @("Connection Broker")
        },
        @{
            NodeName = "SERVER2"
            Role     = @("RdsServer")
        }
    )
    Roles       = @(
        @{
            RoleName = "DNS"
            WindowsFeature = @(
                @{
                    Name = "DNS"
                    Ensure = "Present"
                }
            )
            Services = @(
                @{
                    Name               = "DNS"
                    Ensure             = "Present"
                    ServiceState       = "Running"
                    ServiceStartupType = "Automatic"
                }
            )
        },
        @{
            RoleName = "DHCP"
            WindowsFeature = @(
                @{
                    Name   = "DHCP"
                    Ensure = "Present"
                }
            )
            Services       = @(
                @{
                    Name               = "DHCP"
                    Ensure             = "Present"
                    ServiceState       = "Running"
                    ServiceStartupType = "Automatic"
                }
            )
        }
        @{
            RoleName = "PullServer"
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
                @{
                    Name = "RSAT-DHCP"
                    Ensure = "Present"
                }
                @{
                    Name   = "RSAT-DNS-Server"
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
            #Lsite des package choco
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
            #Liste des clés de registre
            RegistryKeys = @(
                @{
                    Name = "HKEY_LOCAL_MACHINE\SOFTWARE\ExampleKey1"
                    ValueName = "TestValue"
                    ValueData   = "TestData"
                    ValueType = "ExpandString"
                    Ensure = "Present"
                }
            )
            #Liste des packages MSI
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
            #Liste des fichiers
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
    DHCPParams = @{
        Scopes = @(
            @{
                Ensure        = 'Present'
                ScopeId       = '192.168.81.0'
                IPStartRange  = '192.168.81.50'
                IPEndRange    = '192.168.81.100'
                Name          = 'SIEGE'
                SubnetMask    = '255.255.255.0'
                State         = 'Active'
                AddressFamily = 'IPv4'
            }
            @{
                Name          = "Agence"
                Ensure        = "Present"
                ScopeID       = "192.168.82.0"
                IPStartRange  = "192.168.82.50"
                IPEndRange    = "192.168.82.100"
                SubnetMask    = "255.255.255.0"
                State         = 'Active'
                AddressFamily = 'IPv4'
            }
        )
        ServerOptions = @(
            @{
                OptionID = 6
                Value = "192.168.81.1"
                Ensure = "Present"
                AddressFamily = 'IPv4'
                VendorClass   = ''
                UserClass     = ''
            }
            @{
                OptionID      = 15
                Value         = "HIAT.local"
                Ensure        = "Present"
                AddressFamily = 'IPv4'
                VendorClass   = ''
                UserClass     = ''
            }
        )
        ServerAuthorization = @{
            Ensure = "Present"
            DnsName = "SRV01.HIAT.local"
            IpAddress = "192.168.81.1"
        }
        Reservations = @(
            @{
                Name = "SRV01.HIAT.local"
                Ensure = "Present"
                ScopeID = "192.168.81.0"
                ClientMACAddress = "0017FB000000"
                IPAddress = "192.168.81.1"
                AddressFamily = "IPv4"
            }
            @{
                Name             = "SERVER1.HIAT.local"
                Ensure           = "Present"
                ScopeID          = "192.168.81.0"
                ClientMACAddress = "0017FB000002"
                IPAddress        = "192.168.81.2"
                AddressFamily    = "IPv4"
            }
        )

    }
}