<#
.NOTES
Change Log
22-06-2023
    - @slu >>> Ajout de la récupération de la version d'autre logiciel + optimisation du code
17-06-2022
    - @slu >>> Creation du script 
16-06-2022
    - @slu >>> Simplification de la détection du path    
#>
[CmdletBinding()]
param(
[string] $siteInformation,
[string] $agentDescription,
[string] $VersionOfApplication
)

#Information complementaire sur l'agent. Affichage de la description dans le mail d'alerte
write-output "########################################"
write-output "Additional information from the agent:"
write-output $agentDescription
write-output "CashMag Agency: $siteInformation" 
write-output "########################################"

<#
.NOTES
Change Log
17-06-2022
    - @slu >>> Creation du script 
#>


#=========================================================
#FUNCTION
#=========================================================
function get-pathInstallGOMCSuite{
   
   $registryPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\ej-technologies\install4j\installations"


    # Vérifier si la clé de registre existe
    if (Test-Path $registryPath) {
        # Obtenir la valeur de la chaîne spécifiée
        $valueName = 'instdir6855-0348-7121-3187'
        $value = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue
    
        if ($value) {
            #Write-Host "$($value.$valueName)"
            return "$($value.$valueName)"
        } else {
            $valueName = 'instdir6281-3708-5137-9831'
            $value = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue
            if ($value) {
                #Write-Host "$($value.$valueName)"
                return "$($value.$valueName)"
            } 
        }
    }
    
    $registryPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\ej-technologies\install4j\installations"
    if (Test-Path $registryPath) {
        
        if (Test-Path $registryPath) {
            # Obtenir la valeur de la chaîne spécifiée
            $valueName = 'instdir6855-0348-7121-3187'
            $value = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue
    
        if ($value) {
            #Write-Host "$($value.$valueName)"
            return "$($value.$valueName)"
        } else {
            $valueName = 'instdir6281-3708-5137-9831'
            $value = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue
            if ($value) {
                #Write-Host "$($value.$valueName)"
                return "$($value.$valueName)"
            } 
            
        }
        }
    }
}

$restultPathInstallGOMCSuite = get-pathInstallGOMCSuite

function get-PathInstallCMCMoneticWSS{
   
   $registryPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\ej-technologies\install4j\installations"


    # Vérifier si la clé de registre existe
    if (Test-Path $registryPath) {
        # Obtenir la valeur de la chaîne spécifiée
        $valueName = 'instdir9054-5764-4939-3277'
        $value = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue
    
        if ($value) {
            #Write-Host "$($value.$valueName)"
            return "$($value.$valueName)"
        } 
    }
}

$restultPathInstallCMCMoneticWSS = get-PathInstallCMCMoneticWSS


function get-pathInstallshield_x86{
    if ((Get-WmiObject win32_operatingsystem | select osarchitecture).osarchitecture -like  "*64*")
    {
        #64 bit logic here
        #Write "64-bit OS"
        $keyInstallshield_x86 = 'HKLM:\SOFTWARE\WOW6432Node\OMC Gervais\Logiciels OMC Gervais'
        $keyIsPrensent = Test-Path $keyInstallshield_x86
    }
    else
    {
        #32 bit logic here
        #Write "32-bit OS"
        $keyInstallshield_x86 = 'HKLM:\SOFTWARE\OMC Gervais\Logiciels OMC Gervais'
        $keyIsPrensent = Test-Path $keyInstallshield_x86
    }
    
    if ( $keyIsPrensent -eq "True"){
        
        $name0fRegisteryKey = 'install.targetdir'
        $instdirPath = (Get-ItemProperty -Path $keyInstallshield_x86).$name0fRegisteryKey
        
        if($instdirPath.Length -eq 0){
        
        }else{
            return (Get-ItemProperty -Path $keyInstallshield_x86).$name0fRegisteryKey   
        }
        
    }
}
$restultpathInstallshield_x86 = get-pathInstallshield_x86

function Get-FormatVersion {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    $x = $Version

    $tag1 = $x.split(".", 3)[0]
    $tag2 = $x.split(".", 3)[1]
    $tag3 = $x.split(".", 4)[2]
    $tag4 = $x.split(".", 5)[3]

    # Conversion du chiffre de la version en lettre
    if ($tag4 -ne "0") {
        for ($letter = 0; $letter -lt $tag4.Length; $letter++) {
            $versionletter = [char](65 + $tag4 - 1)
        }
    } else {
        $versionletter = $tag4
    }

    # Recontruction de la version avec la lettre
    $FormattedVersion = "$tag1.$tag2.$tag3.$versionletter"

    return $FormattedVersion
}

#=========================================================
#MAIN
#=========================================================

#Si un repertoire d'installation GOMCPos est trouve 
If ($restultPathInstallGOMCSuite -ne "nothing") {
    $pathGOMCPos = "$restultPathInstallGOMCSuite\CashmagGomcPos.exe"

    #Recuperation de la version de l'appli restau.exe s'il existe
    if (Test-Path $pathGOMCPos -PathType leaf){
      $versionProgrammeGOMCPos = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$pathGOMCPos").FileVersion

        if ($versionProgrammeGOMCPos.Contains(",")){
            # Remplacer les virgules par des points dans la valeur de FileVersion
            $versionProgrammeGOMCPos = $versionProgrammeGOMCPos.Replace(",", ".")
        }
        
        #Formatage de la version
        $formattedVersion = Get-FormatVersion -Version $versionProgrammeGOMCPos
      
      #affichage de la version final
      write-output "---------------------------------------------"
      write-output "Version du logiciel GOMCPos"
      write-output "---------------------------------------------"
      write-output $formattedVersion
      $VersionOfApplication = $formattedVersion
    }
 }
 
 ############################################################################################
 
 #Si un repertoire d'installation WSServer est trouve 
If ($restultPathInstallCMCMoneticWSS -ne "nothing") {
    $CMCMoneticWSS = "$restultPathInstallCMCMoneticWSS\cm.CMCApi.WSServer.exe"

    #Recuperation de la version de l'appli restau.exe s'il existe
    if (Test-Path $CMCMoneticWSS -PathType leaf){
      $versionProgrammeCMCMoneticWSS = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$CMCMoneticWSS").FileVersion

        if ($versionProgrammeCMCMoneticWSS.Contains(","))
        {
            # Remplacer les virgules par des points dans la valeur de FileVersion
            $versionProgrammeCMCMoneticWSS = $versionProgrammeCMCMoneticWSS.Replace(",", ".")
        }
      
      #Formatage de la version
      $formattedVersion = Get-FormatVersion -Version $versionProgrammeCMCMoneticWSS
            
      #affichage de la version final
      write-output "---------------------------------------------"
      write-output "Version du logiciel CMCMoneticWSS"
      write-output "---------------------------------------------"
      write-output $formattedVersion
      $VersionOfApplication = $formattedVersion
    }
 }

 ############################################################################################

#Si un repertoire d'installation Restau est trouve 
If ($restultpathInstallshield_x86 -ne "nothing") {
    $pathGOMCPos = "$restultpathInstallshield_x86\Restau\restau.exe"

    #Recuperation de la version de l'appli restau.exe s'il existe
    if (Test-Path $pathGOMCPos -PathType leaf){
  
      $versionProgrammeRestau = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$pathGOMCPos").FileVersion

      if ($versionProgrammeRestau.Contains(","))
        {
            # Remplacer les virgules par des points dans la valeur de FileVersion
            $versionProgrammeRestau = $versionProgrammeRestau.Replace(",", ".")
        }
      
      #Formatage de la version
      $formattedVersion = Get-FormatVersion -Version $versionProgrammeRestau
            
      #affichage de la version final
      write-output "---------------------------------------------"
      write-output "Version du logiciel Restau"
      write-output "---------------------------------------------"
      write-output $formattedVersion
      $VersionOfApplication = $formattedVersion
    }      
}

############################################################################################

    $uninstallKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
#Si un repertoire d'installation Atoo 64bits est trouve    
     if (Test-Path $uninstallKey){
        # Récupérer les sous-clés de registre correspondant aux programmes installés
        $programs = Get-ChildItem $uninstallKey | Get-ItemProperty
       
        # Filtrer uniquement les logiciels commençant par "ATOO LEO2"
        $atooLeo2 = $programs | Where-Object { $_.DisplayName -like "ATOO LEO2*" }
        
        # Afficher les noms et versions des logiciels correspondants
        if ($atooLeo2) {
        
            foreach ($program in $atooLeo2) {
                 #affichage de la version final
                write-output "---------------------------------------------"
                write-output "Version du logiciel Leo"
                write-output "---------------------------------------------"
                Write-Host "$($program.DisplayVersion)"
            }
        }
    }
    
    $uninstallKeyWoW = "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"

#Si un repertoire d'installation Atoo 32Bits est trouve        
     if (Test-Path $uninstallKey){
        # Récupérer les sous-clés de registre correspondant aux programmes installés
        $programs = Get-ChildItem $uninstallKey | Get-ItemProperty

        # Filtrer uniquement les logiciels commençant par "ATOO LEO2"
        $atooLeo2 = $programs | Where-Object { $_.DisplayName -like "ATOO LEO2*" }
        
        # Afficher les noms et versions des logiciels correspondants
        if ($atooLeo2) {
        
            foreach ($program in $atooLeo2) {
                 #affichage de la version final
                write-output "---------------------------------------------"
                write-output "Version du logiciel Leo"
                write-output "---------------------------------------------"
                Write-Host "$($program.DisplayVersion)"
            }
        }
    }
$host.SetShouldExit($exitcode)
exit
