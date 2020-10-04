#Les ressources disponible localement
Get-DscResource -Module PSDesiredStateConfiguration

Get-DscResource -Name File -Syntax

<# File [String] #ResourceName
{
    DestinationPath = [string]
    [Attributes = [string[]]{ Archive | Hidden | ReadOnly | System }]
    [Checksum = [string]{ CreatedDate | ModifiedDate | SHA-1 | SHA-256 | SHA-512 }]
    [Contents = [string]]
    [Credential = [PSCredential]]
    [DependsOn = [string[]]]
    [Ensure = [string]{ Absent | Present }]
    [Force = [bool]]
    [MatchSource = [bool]]
    [PsDscRunAsCredential = [PSCredential]]
    [Recurse = [bool]]
    [SourcePath = [string]]
    [Type = [string]{ Directory | File }]
} #>

Get-DscResource -Name Service -Module PSDesiredStateConfiguration | Select-Object *

#3 principales fonctions dans une ressource
#Get
#Set
#Test
code "C:\Windows\system32\WindowsPowershell\v1.0\Modules\PsDesiredStateConfiguration\DscResources\MSFT_ServiceResource\MSFT_ServiceResource.psm1"

#List des resources disponible sur la gallery
Find-DSCResource

(Find-DSCResource).Count