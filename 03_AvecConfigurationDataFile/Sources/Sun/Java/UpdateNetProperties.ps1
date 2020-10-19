[CmdletBinding()]
param (
    [parameter(Mandatory=$false,Position=0)][System.string]$JavaPath = 'C:\Program Files (x86)\Java',
    [parameter(Mandatory=$false,Position=1)][System.String]$JavaFile = "net.properties",
    [parameter(Mandatory=$false,Position=2)][System.String]$JavaProperties = "jdk.http.ntlm.transparentAuth",
    [parameter(Mandatory=$false,Position=4)][System.String]$NewValue = "trustedHosts",
    [parameter(Mandatory=$false,Position=5)][System.String]$Separator = "="
)


try {
    Clear-Host

    $OldString = "(^$JavaProperties$Separator)(\D*)"
    $NewString = "$JavaProperties$Separator$NewValue"

    Write-Verbose "Modification de la cle $($JavaProperties) dans le fichier $($JavaFile) : Changement de la valeur $($OldString) vers $($NewString)"

    if (Test-Path $JavaPath) {
        Write-Verbose "Recherche du fichier $($JavaFile) dans le dossier $($JavaPath)"
        $Files =  Get-ChildItem -Path $JavaPath -Recurse -Filter $JavaFile
        
        foreach ($file in $Files) {
            Write-Verbose "Traitement de $($file.FullName)"
            (Get-Content -Path $File.FullName) -replace $OldString,$NewString | set-content $File.FullName -Force
        }
    }
}
catch {
    
}