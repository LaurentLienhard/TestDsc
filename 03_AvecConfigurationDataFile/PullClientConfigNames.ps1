$RegKeyFromLocation = Get-Content -Path 'C:\Program Files\WindowsPowerShell\DSCService\RegistrationKeys.txt'

[DSCLocalConfigurationManager()]
configuration PullClientConfigNames {
        Node $AllNodes.NodeName {
            Settings {
                ConfigurationMode = 'ApplyAndAutoCorrect'
                ActionAfterReboot = 'ContinueConfiguration'
                RefreshMode = 'Pull'
                RefreshFrequencyMins = 30
                ConfigurationModeFrequencyMins = 15
                RebootNodeIfNeeded = $true
                AllowModuleOverwrite = $true
            }

            ConfigurationRepositoryWeb SRV01 {
                ServerURL = "https://SRV01:8080/PSDSCPullServer.svc"
                RegistrationKey = $RegKeyFromLocation
                ConfigurationNames = @($NodeName)
            }

            ResourceRepositoryWeb SRV01 {
                ServerURL = "https://SRV01:8080/PSDSCPullServer.svc"
            }
        }
    }

PullClientConfigNames -ConfigurationData ".\ConfigurationData.psd1" -OutputPath "../LCMFiles"

Set-DSCLocalConfigurationManager -Path ../LCMFiles -Verbose