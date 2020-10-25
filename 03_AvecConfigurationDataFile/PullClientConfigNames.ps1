$RegKeyFromLocation = Get-Content -Path 'C:\Program Files\WindowsPowerShell\DSCService\RegistrationKeys.txt'

[DSCLocalConfigurationManager()]
configuration PullClientConfigNames {
        Node $AllNodes.NodeName {
            $LCMConfig = $configurationData.LCMParams
            Settings {
                ConfigurationMode = $LCMConfig.LCMConfigurationMode
                ActionAfterReboot = $LCMConfig.LCMActionAfterReboot
                RefreshMode = $LCMConfig.LCMRefreshMode
                RefreshFrequencyMins = $LCMConfig.LCMRefreshFrequencyMins
                ConfigurationModeFrequencyMins = $LCMConfig.LCMConfigurationModeFrequencyMins
                RebootNodeIfNeeded = $LCMConfig.LCMRebootNodeIfNeeded
                AllowModuleOverwrite = $LCMConfig.LCMAllowModuleOverwrite
            }

            ConfigurationRepositoryWeb SRV01 {
                ServerURL = $LCMConfig.LCMServerUrl
                RegistrationKey = $RegKeyFromLocation
                ConfigurationNames = @($NodeName)
            }

            ResourceRepositoryWeb SRV01 {
                ServerURL = $LCMConfig.LCMServerUrl
            }
        }
    }

PullClientConfigNames -ConfigurationData ".\ConfigurationData.psd1" -OutputPath "./LCMFiles"

#Set-DSCLocalConfigurationManager -Path ./LCMFiles -Verbose