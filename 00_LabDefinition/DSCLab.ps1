<#
    https://github.com/AutomatedLab/AutomatedLab
    Installation de AutomatedLab :
        Install-Module AutomatedLab
        New-LabSourcesFolder -DriveLetter D  => Création des dossiers sur le lecteur D

    Ensuite mettre les iso dans le dossier Iso qui va être créé et les tester
    Get-LabAvailableOperatingSystem -Path D:\LabSources   => va scanner tout les Iso

    Faire son script de lab :-)
#>

$Labname = "DSCLab"
$Domain = "HIAT.local"

New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV -VmPath "Y:/Labs"

#make the network definition
Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.81.0/24
Add-LabVirtualNetworkDefinition -Name 'Default Switch' -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Ethernet 4' }

# And the domain definition with the domain admin account
Add-LabDomainDefinition -Name $Domain -AdminUser "Install" -AdminPassword "Somepass1"

Set-LabInstallationCredential -Username "Install" -Password "Somepass1"

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network'    = $labName
    'Add-LabMachineDefinition:DomainName' = $Domain
    'Add-LabMachineDefinition:Memory'     = 2GB
}

$Roles = @()
$Roles += Get-LabMachineRoleDefinition -Role RootDC
$Roles += Get-LabMachineRoleDefinition -Role Routing
$Roles += Get-LabMachineRoleDefinition -Role CaRoot
$Roles += Get-LabMachineRoleDefinition -Role DSCPullServer


$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch $labName -Ipv4Address 192.168.81.1 -Ipv4DNSServers 192.168.81.1
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'Default Switch' -UseDhcp

$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name SRV01 -Roles $Roles -PostInstallationActivity $postInstallActivity -NetworkAdapter $netAdapter -OperatingSystem 'Windows Server 2019 Datacenter'

#DSC Pull Clients
Add-LabMachineDefinition -Name Server1 -Memory 4Gb -IpAddress 192.168.81.2 -DnsServer1 192.168.81.1 -OperatingSystem 'Windows Server 2019 Standard (Desktop Experience)'
Add-LabMachineDefinition -Name Server2 -Memory 4Gb -IpAddress 192.168.81.3 -DnsServer1 192.168.81.1 -OperatingSystem 'Windows Server 2019 Standard (Desktop Experience)'
#Add-LabMachineDefinition -Name SRVSql -Memory 1Gb -IpAddress 192.168.81.4 -DnsServer1 192.168.81.1 -OperatingSystem 'Windows Server 2019 Datacenter'

Install-Lab
Install-LabDscClient -All
Show-LabDeploymentSummary -Detailed