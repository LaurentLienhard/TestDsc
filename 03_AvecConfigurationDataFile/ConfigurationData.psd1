@{
    AllNodes  = @(
            @{
                NodeName = "*"
                WindowsFeature = "SNMP-Service", "SNMP-WMI-Provider"
                Services       = "SNMP"
                Ensure  = "Present"
                ServiceState = "Running"
                ServiceStartupType = "Automatic"
            }
            @{
                NodeName = "SRV01"
                Role     = @("PullServer","DomainController","RootCA","Routeur")
            }
            @{
                NodeName = @("SERVER1","SERVER2")
                Role = "RdsServer"
            }
        )
    Roles = @(
            @{
                RoleName = "PullServer"
                Modules = "PSDesiredStateConfiguration", "chocolatey", "ComputerManagementDsc", "SqlServerDsc", "ActiveDirectoryDsc"
            }
            @{
                RoleName = "DomainController"
                WindowsFeature = "AD-Domain-Services","RSAT-AD-PowerShell"
                Services = "DNS", "NTDS"
            }
            @{
                RoleName = "RdsServer"
                WindowsFeature = "RDS-RD-Server"
                ChocoPackages  = "javaruntime" , "7zip.install"
            }
        )
    ChocoParams = @{
        ChocoInstallDir = "$env:ProgramData\Chocolatey"
        ChocoTempDir    = "$env:Temp\Chocolatey"
        ChocoSource     = 'https://chocolatey.org/api/v2'
    }
}
