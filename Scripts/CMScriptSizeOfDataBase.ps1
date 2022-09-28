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

function get-dataDirGOMCSuite_POS_x64{
    if ($restultPathInstallGOMCSuite_x64.length -gt 0){
        $dataBasePath = convertfrom-stringdata (get-content $restultPathInstallGOMCSuite_x64'\.install4j\response.varfile' -raw)
        $dataBasePath =  $dataBasePath.'localDataDbDir'
        $resultDataPathGOMCSuite_POS = $dataBasePath + "\POS\restau.db"
        return $resultDataPathGOMCSuite_POS
    }
}
 
function get-dataDirGOMCSuite_GOMC_x64{
    if ($restultPathInstallGOMCSuite_x64.length -gt 0){
    $dataBasePath = convertfrom-stringdata (get-content $restultPathInstallGOMCSuite_x64'\.install4j\response.varfile' -raw)
    $dataBasePath =  $dataBasePath.'localDataDbDir'
    $resultDataPathGOMCSuite_GOMC = $dataBasePath + "\GOMC\gescom.db"
    return $resultDataPathGOMCSuite_GOMC
    }
}

function get-dataDirGOMCSuite_POS_x86{
        
    if ($restultPathInstallGOMCSuite_x86.length -gt 0 ){
        $dataBasePath = convertfrom-stringdata (get-content $restultPathInstallGOMCSuite_x86'\.install4j\response.varfile' -raw)
        $dataBasePath =  $dataBasePath.'localDataDbDir'
        $resultDataPathGOMCSuite_POS = $dataBasePath + "\POS\restau.db"
        return $resultDataPathGOMCSuite_POS
    }    
}

function get-dataDirGOMCSuite_GOMC_x86{
    if ($restultPathInstallGOMCSuite_x86.length -gt 0){
        $dataBasePath = convertfrom-stringdata (get-content $restultPathInstallGOMCSuite_x86'\.install4j\response.varfile' -raw)
        $dataBasePath =  $dataBasePath.'localDataDbDir'
        $resultDataPathGOMCSuite_GOMC = $dataBasePath + "\GOMC\gescom.db"
        return $resultDataPathGOMCSuite_GOMC
    }    
}

#=========================================================
#MAIN
#=========================================================
$resultDataPathGOMCSuite_POS_64 = get-dataDirGOMCSuite_POS_x64
$resultDataPathGOMCSuite_GOMC_64 = get-dataDirGOMCSuite_GOMC_x64

if($restultPathInstallGOMCSuite_x64.Length -gt 0 -and $resultDataPathGOMCSuite_POS_64.length -gt 0){
      
    "-----------------------------------------------------------------"
    "File size Restau.db (GOMCSuites x64)"
    "-----------------------------------------------------------------"
    #Read size of file restau.log
    if (Test-Path $resultDataPathGOMCSuite_POS_64 -PathType leaf){
    
        #Recuperation de la taille du fichier log et conversion en Mo   
        $sileFile = [math]::Round(((Get-Item $resultDataPathGOMCSuite_POS_64).length/1MB),2)
    
            Write-Output "Information >>> The size of the Data file is"
            $sizeOfDataBase = $sileFile
            Write-Output $sizeOfDataBase" Mo"
    }else{
        Write-Output "No file Restau.db found !"
    }
}          
                
if($restultPathInstallGOMCSuite_x64.Length -gt 0 -and $resultDataPathGOMCSuite_GOMC_64.length -gt 0){   
    #Read size of file gomc.log
    if (Test-Path $resultDataPathGOMCSuite_GOMC_64 -PathType leaf){
        "-----------------------------------------------------------------"
        "File size Gescom.db (GOMCSuites x64)"
        "-----------------------------------------------------------------"
        #Recuperation de la taille du fichier log et conversion en Mo   
        $sileFile = [math]::Round(((Get-Item $resultDataPathGOMCSuite_GOMC_64).length/1MB),2)
    
        Write-Output "Information >>> The size of the Data file is"
        $sizeOfDataBase = $sileFile
        Write-Output $sizeOfDataBase" Mo"
     
    }else{
        
    }
} 

$resultDataPathGOMCSuite_POS_x86 = get-dataDirGOMCSuite_POS_x86
$resultDataPathGOMCSuite_GOMC_x86 = get-dataDirGOMCSuite_GOMC_x86


if($restultPathInstallGOMCSuite_x86.Length -gt 0 -and $resultDataPathGOMCSuite_POS_x86.length -gt 0){
    
    #$resultDataPathGOMCSuite_POS = get-dataDirGOMCSuite_POS
    #$resultDataPathGOMCSuite_GOMC = get-dataDirGOMCSuite_GOMC
    
    "-----------------------------------------------------------------"
    "File size Restau.db (GOMCSuites x86)"
    "-----------------------------------------------------------------"
    #Read size of file restau.log
    if (Test-Path $resultDataPathGOMCSuite_POS_x86 -PathType leaf){
    
        #Recuperation de la taille du fichier log et conversion en Mo   
        $sileFile = [math]::Round(((Get-Item $resultDataPathGOMCSuite_POS_x86).length/1MB),2)
   
      Write-Output "Information >>> The size of the Data file is"
      $sizeOfDataBase = $sileFile
      Write-Output $sizeOfDataBase" Mo"
    }else{
        Write-Output "No file Restau.db found !"
    }
}           
                
if($restultPathInstallGOMCSuite_x86.Length -gt 0 -and $resultDataPathGOMCSuite_GOMC_x86.length -gt 0){
    "-----------------------------------------------------------------"
    "File size Gescom.db (GOMCSuites x86)"
    "-----------------------------------------------------------------"
    #Read size of file gescom.log
    if (Test-Path $resultDataPathGOMCSuite_GOMC_x86 -PathType leaf){

        #Recuperation de la taille du fichier log et conversion en Mo   
        $sileFile = [math]::Round(((Get-Item $resultDataPathGOMCSuite_GOMC_x86).length/1MB),2)

        Write-Output "Information >>> The size of the Data file is"
        $sizeOfDataBase = $sileFile
        Write-Output $sizeOfDataBase" Mo"
    }else{
        Write-Output "No file Gescom.db found !"
    }
}

$pathGOMCPos = "C:/OMC/BASESD~1/Restau/restau.db"
#if($restultpathInstallshield_x86.Length -gt 0 -and $pathGOMCPos.Length -gt 0){

    
    #Get value data base
    #$pathGOMCPos = "C:/OMC/BASESD~1/Restau/restau.db"
    

    #Read size of file restau.log
    if (Test-Path $pathGOMCPos -PathType leaf){

        "-----------------------------------------------------------------"
        "File size Restau.db (installshield x86)"
        "-----------------------------------------------------------------"
        
        #Recuperation de la taille du fichier log et conversion en Mo   
        $sileFile = [math]::Round(((Get-Item $pathGOMCPos).length/1MB),2)

        Write-Output "Information >>> The size of the Data file is"
        $sizeOfDataBase = $sileFile
        Write-Output $sizeOfDataBase" Mo"
    }
#}

$pathGOMC = "C:/OMC/BASESD~1/GesCom/Gescom.db"
#if($restultpathInstallshield_x86.Length -gt 0 -and $pathGOMC.Length -gt 0){           
     #Read size of file GOMC.log
    if (Test-Path $pathGOMC -PathType leaf){
        "-----------------------------------------------------------------"
        "File size Gescom.db (installshield x86)"
        "-----------------------------------------------------------------"
    
        #Recuperation de la taille du fichier log et conversion en Mo   
        $sileFile = [math]::Round(((Get-Item $pathGOMC).length/1MB),2)
    
        Write-Output "Information >>> The size of the Data file is"
        $sizeOfDataBase = $sileFile
        Write-Output $sizeOfDataBase" Mo"
    }
#}