Configuration ConfigurationServer {
    Import-DscResource –ModuleName PSDesiredStateConfiguration, cChoco, ComputerManagementDsc, xDhcpServer
    Import-DscResource -ModuleName PowerShellGet -ModuleVersion "2.2.5"


    Node $AllNodes.NodeName {
        #region <Configure All Node>
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
        #endregion <Configure All Node>

        #region <Configure All DNS Server>
        if ($Node.Role -contains "DNS") {
            #Install Feature for DNS Server
            foreach ($Feature in $ConfigurationData.Roles.Where{ $_.RoleName -Contains 'DNS' }.WindowsFeature) {
                WindowsFeature $Feature.Name {
                    Name   = $Feature.name
                    Ensure = $Feature.Ensure
                }
            }

            #Install services for DNS Server
            foreach ($Service in $ConfigurationData.Roles.where{ $_.RoleName -Contains 'DNS' }.Services) {
                Service $Service.Name {
                    Name        = $Service.Name
                    Ensure      = $Service.Ensure
                    StartupType = $Service.ServiceStartupType
                    State       = $Service.ServiceState
                }
            }
        }
        #endregion <Configure All DNS Server>

        #region <Configure All DHCP Server>
        if ($Node.Role -contains "DHCP") {
            #Install Feature for DHCP Server
            foreach ($Feature in $ConfigurationData.Roles.Where{ $_.RoleName -Contains 'DHCP' }.WindowsFeature) {
                WindowsFeature $Feature.Name {
                    Name   = $Feature.name
                    Ensure = $Feature.Ensure
                }
            }

            #Install services for DHCP Server
            foreach ($Service in $ConfigurationData.Roles.where{ $_.RoleName -Contains 'DHCP' }.Services) {
                Service $Service.Name {
                    Name        = $Service.Name
                    Ensure      = $Service.Ensure
                    StartupType = $Service.ServiceStartupType
                    State       = $Service.ServiceState
                }
            }

            foreach($scope in $ConfigurationData.DHCPParams.Scopes) {
                xDhcpServerScope $scope.name {
                    Name = $scope.Name
                    ScopeId = $scope.ScopeID
                    IPStartRange = $scope.IPStartRange
                    IPEndRange = $scope.IPEndRange
                    SubnetMask = $scope.SubnetMask
                    State = $scope.State
                    AddressFamily = $scope.AddressFamily
                }
            }

            foreach($ServerOption in $ConfigurationData.DHCPParams.ServerOptions) {
                DhcpServerOptionValue $ServerOption.OptionID {
                    OptionId = $ServerOption.OptionId
                    Value = $ServerOption.Value
                    Ensure = $ServerOption.Ensure
                    AddressFamily = $ServerOption.AddressFamily
                    VendorClass   = $ServerOption.VendorClass
                    UserClass = $ServerOption.UserClass
                }
            }

            xDhcpServerAuthorization $Node {
                Ensure         = $ConfigurationData.DHCPParams.ServerAuthorization.Ensure
                DnsName        = $ConfigurationData.DHCPParams.ServerAuthorization.DnsName
                IPAddress      = $ConfigurationData.DHCPParams.ServerAuthorization.IPAddress
            }

            foreach($Reservation in $ConfigurationData.DHCPParams.Reservations) {
                xDhcpServerReservation $Reservation.Name {
                    Name = $Reservation.name
                    Ensure = $Reservation.Ensure
                    ScopeID = $Reservation.ScopeID
                    ClientMACAddress = $Reservation.ClientMACAddress
                    IPAddress = $Reservation.IPAddress
                    AddressFamily = $Reservation.AddressFamily
                }
            }
        }
        #endregion <Configure All DHCP Server>

        #region <Configure All Pull Server>
        if ($Node.Role -contains "PullServer") {

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
        #endregion <Configure All Pull Server>

        #region <Configure All Domain Controller>
        if ($Node.Role -contains 'DomainController') {
            foreach ($Feature in $ConfigurationData.Roles.Where{ $_.RoleName -Contains 'DomainController' }.WindowsFeature) {
                WindowsFeature $Feature.Name {
                    Name   = $Feature.name
                    Ensure = $Feature.Ensure
                }
            }

            #Install services for Domain Controller
            foreach ($Service in $ConfigurationData.Roles.where{ $_.RoleName -Contains 'DomainController' }.Services) {
                Service $Service.Name {
                    Name        = $Service.Name
                    Ensure      = $Service.Ensure
                    StartupType = $Service.ServiceStartupType
                    State       = $Service.ServiceState
                }
            }
        }
        #endregion <Configure All Domain Controller>

        #region <Configure All Connection Broker>
        if ($Node.Role -contains 'Connection Broker') {
            foreach ($Feature in $ConfigurationData.Roles.Where{ $_.RoleName -Contains 'Connection Broker' }.WindowsFeature) {
                WindowsFeature $Feature.name {
                    Name   = $Feature.Name
                    Ensure = $Feature.Ensure
                }
            }
        }
        #endregion <Configure All Connection Broker>

        #region <Configure All RDS Server>
        if ($Node.Role -Contains 'RdsServer' ) {
            #Install feature for Rds Server
            foreach ($Feature in $ConfigurationData.Roles.Where{ $_.RoleName -Contains 'RdsServer' }.WindowsFeature) {
                WindowsFeature $Feature.Name {
                    Name   = $Feature.Name
                    Ensure = $Feature.Ensure
                }
            }

            #Install MSI Package for Rds Server
            foreach ($MSI in $ConfigurationData.Roles.Where{ $_.RoleName -Contains 'RdsServer' }.MsiPackages) {
                Package $MSI.Name {
                    Name = $MSI.name
                    Path = $MSI.path
                    ProductId = $MSI.ProductId
                    Arguments = $MSI.Arguments
                    Ensure = $MSI.Ensure
                }
            }

            #Copy ALl Files to Rds Server
            foreach ($File in $ConfigurationData.Roles.Where{ $_.RoleName -Contains 'RdsServer' }.Files) {
                File $File.Name {
                    SourcePath = $File.SourcePath
                    DestinationPath = $File.DestinationPath
                    Type = $File.Type
                    MatchSource = $File.MatchSource
                    Checksum = $File.Checksum
                    Ensure = $File.Ensure
                }
            }

            #Install All registry Key for Rds Server
            foreach ($Key in $ConfigurationData.Roles.where{ $_.RoleName -eq 'RdsServer' }.RegistryKeys) {
                Registry $Key.Name {
                    Ensure    = $Key.Ensure
                    Key       = $Key.Name
                    ValueName = $Key.ValueName
                    ValueData = $Key.ValueData
                    ValueType = $Key.ValueType
                }
            }

            #region <ChocoPackage>
            #Install Chocolatey on Server RDS
            cChocoInstaller "InstallChoco" {
                InstallDir = $ConfigurationData.ChocoParams.ChocoInstallDir
            }

            #Install chocolatey package for Server RDS
            foreach ($Package in $ConfigurationData.Roles.where{ $_.RoleName -eq 'RdsServer' }.ChocoPackages) {
                if ($Package.Params) {
                    cChocoPackageInstaller $Package.Name {
                        Name        = $Package.Name
                        Ensure      = $Package.Ensure
                        Version     = $Package.Version
                        chocoParams = $Package.Params
                        DependsOn   = '[cChocoInstaller]InstallChoco'
                    }
                } else {
                    cChocoPackageInstaller $Package.Name {
                        Name        = $Package.Name
                        Ensure      = $Package.Ensure
                        Version     = $Package.Version
                        DependsOn   = '[cChocoInstaller]InstallChoco'
                    }
                }
            }
            #endregion <ChocoPackage>
        }
        #endregion <Configure All RDS Server>
    }
}

ConfigurationServer -ConfigurationData ".\ConfigurationData.psd1" -OutputPath ".\MOFFiles"
Get-ChildItem -Path C:\Test\Configuration\MOFFiles | ForEach-Object {
$MofName = $_.Name
$DestinationMof = "C:\Program Files\WindowsPowershell\DSCService\Configuration\$MofName"
Copy-Item $_.FullName $DestinationMof
New-DscChecksum $DestinationMof -force
}
#Start-DscConfiguration -Wait -Verbose -Path "C:\Test\Dsc" -Force
#Test-DscConfiguration -Path "C:\Test\Dsc"