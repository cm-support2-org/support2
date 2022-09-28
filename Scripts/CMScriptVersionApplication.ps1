<#
.NOTES
Change Log
17-06-2022
    - @slu >>> Creation du script 
#>


#=========================================================
#FUNCTION
#=========================================================
function get-pathInstallGOMCSuite_x64{
    $keyInstall4j_x64 = 'HKLM:\SOFTWARE\ej-technologies\install4j\installations'
    $keyIsPrensent = Test-Path $keyInstall4j_x64

    if ( $keyIsPrensent -eq "True"){
        
        $name0fRegisteryKey = 'instdir6281-3708-5137-9831'
        $instdirPath = (Get-ItemProperty -Path $keyInstall4j_x64).$name0fRegisteryKey
        
        if($instdirPath.Length -eq 0){
        
        }else{
            return (Get-ItemProperty -Path $keyInstall4j_x64).$name0fRegisteryKey   
        }
        
    }
}
$restultPathInstallGOMCSuite_x64 = get-pathInstallGOMCSuite_x64

function get-pathInstallGOMCSuite_x86{
    $keyInstall4j_x86 = 'HKLM:\SOFTWARE\WOW6432Node\ej-technologies\install4j\installations'
    $keyIsPrensent = Test-Path $keyInstall4j_x86

    if ( $keyIsPrensent -eq "True"){
        
        $name0fRegisteryKey = 'instdir6855-0348-7121-3187'
        $instdirPath = (Get-ItemProperty -Path $keyInstall4j_x86).$name0fRegisteryKey
        
        if($instdirPath.Length -eq 0){
        
        }else{
            return (Get-ItemProperty -Path $keyInstall4j_x86).$name0fRegisteryKey   
        }
        
    }
}
$restultPathInstallGOMCSuite_x86 = get-pathInstallGOMCSuite_x86

function get-pathInstallshield_x86{
    $keyInstallshield_x86 = 'HKLM:\SOFTWARE\WOW6432Node\OMC Gervais\Logiciels OMC Gervais'
    $keyIsPrensent = Test-Path $keyInstallshield_x86

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



#=========================================================
#MAIN
#=========================================================
#Si un repertoire d'installation est trouve 
If ($restultPathInstallGOMCSuite_x64 -ne "nothing") {
    $pathGOMCPos = "$restultPathInstallGOMCSuite_x64\CashmagGomcPos.exe"

    #Recuperation de la version de l'appli restau.exe s'il existe
    if (Test-Path $pathGOMCPos -PathType leaf){
      $versionProgrammeRestau = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$pathGOMCPos").FileVersion
      
      #Decoupage de la version par morceaux 
      $x = $versionProgrammeRestau 

      $tag1 = $x.split(",",3)[0]
      $tag2 = $x.split(",",3)[1]
      $tag3 = $x.split(",",4)[2]
      $tag4 = $x.split(",",5)[3]

      #convertion du chiffre de la version en lettre
      for ($letter= 0; $letter-lt $tag4.Length; $letter++)
      {
        $versionletter = [char](65 + $tag4 -1)
      }
      
      #recontruction de la version avec la lettre 
      $versionProgrammeRestau = "$tag1.$tag2.$tag3.$versionletter"
            
      #affichage de la version final
      write-output "---------------------------------------------"
      write-output "Version du logiciel Restau"
      write-output "---------------------------------------------"
      write-output $versionProgrammeRestau
    }else{
      
      #l'exe n'existe pas a l'emplacement indique      
    }
 }else{
      
      #l'exe n'existe pas a l'emplacement indique      
}
$host.SetShouldExit($exitcode)
exit