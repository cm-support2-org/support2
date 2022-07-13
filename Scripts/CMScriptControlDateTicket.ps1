<#
.Description
Contole la date du plus ancien ticket. Selon l'annee du ticket une alerte est declencher pour inviter le service technique a effectuer une epuration.
.NOTES
Change Log
#>
$ExitCode = 0
#Verification si le fichier existe. S'il existe pas creation
$fileToMessage = "$env:TEMP\CMErrorDateTicket.txt"

if (Test-Path $fileToMessage -PathType leaf)
{
    #Si le fichier existe  
}
else
{
    #Creation du fichier
    Set-Content $fileToMessage ""
}

Function ODBCConnection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,
                    HelpMessage="DSN name of ODBC connection")]
                    [string]$dsn,
                    [string]$query,
                    [bool]$lbvalide,
                    [string]$Message,
                    [string]$ResultQuery
    )
    
    $conn = new-object system.data.odbc.odbcconnection
    $conn.connectionstring = "DSN=$dsn"                      
    
    #Ouverture de l a connexion
    $opened = $false
    try {

        $conn.Open()
        
        #Ouverture ok
        $opened = $True
    } catch {
        
        #Erreur
        $errorMessage = $_.Exception.Message
        #Ecrire message
        Add-Content $fileToMessage $_.Exception.Message
        $ExitCode = 1
  
    }
    
    #Execute query si connexion ok
    If ($opened -eq $true){
        
        $cmd = New-object System.Data.Odbc.OdbcCommand($query,$conn)
        $ds = New-Object system.Data.DataSet
        (New-Object system.Data.odbc.odbcDataAdapter($cmd)).fill($ds) | out-null
      
        $ds.Tables[0]
                
        if ($ds.Tables[0].Rows.Count -gt 0){
           
            $ResultQuery = $ds.Tables[0]

            #Ecrire le message dans un fichier text           
            Add-Content $fileToMessage $Message 

            foreach ($Row in $ds.Tables[0].Rows) { 
                
                $DateTicket = $($Row.DateTicket)                
                $today = $(Get-Date -Format "yyyy")
                
                #Calcul de la difference d'annees               
                $diffAnnee = $today -$DateTicket
                
               if ($diffAnnee -gt 2){
                    $lbvalide = $false

                    Add-Content $fileToMessage "---------------------------------------------------------------------------"	            
                    Add-Content $fileToMessage "We advise you to purify the tickets."
                    Add-Content $fileToMessage "Data is present from: $($Row.DateTicket)"
	                Add-Content $fileToMessage "---------------------------------------------------------------------------"

                }else{

                    Add-Content $fileToMessage "---------------------------------------------------------------------------"	            
                    Add-Content $fileToMessage "Data cleansing is not currently advised. !"                    
	                Add-Content $fileToMessage "---------------------------------------------------------------------------"

                    #Ecrire message
                    Add-Content $fileToMessage $Message 
                    $ExitCode = 0
                    $lbvalide = $True                
                }
            
            }
            
        }
        else
        {

        
        }                   
            
        #Fermeture de la connexion avec la base
        $conn.close()     

        if ($lbvalide -eq $false){
            $ExitCode = 1
        }
     
    } 
  
    #exit $ExitCode
}

#=========================================================
#FUNCTION
#=========================================================
function get-pathInstallGOMCSuite(){

    $keyInstall4j_x64 = 'HKLM:\SOFTWARE\ej-technologies\install4j\installations'
    $keyInstall4j_x86 = 'HKLM:\SOFTWARE\WOW6432Node\ej-technologies\install4j\installations'
    $instdirPath = ''

   
    #Est ce qu'une clé x64 est présente ?
    $keyIsPrensent = Test-Path $keyInstall4j_x64
    if ( $keyIsPrensent -eq "True"){
    
        #Oui
        $instdirPath = (Get-ItemProperty -Path $keyInstall4j_x64).'instdir6281-3708-5137-9831'

    } else {

        #Non
        #Est ce qu'une clé x86 est présente ?    
        $keyIsPrensent = Test-Path $keyInstall4j_x86
        if ( $keyIsPrensent -eq "True") {
        
            #Oui
            $instdirPath = (Get-ItemProperty -Path $keyInstall4j_x86).'instdir6855-0348-7121-3187'
        }
    }

    # sortir si le chemin d'installation n'est pas present
    if($instdirPath.Length -eq 0){
        return
    }

    $DSN_Name_GOMC = convertfrom-stringdata (get-content $instdirPath'\.install4j\response.varfile' -raw)        
    $DSN_Name_GOMC =  $DSN_Name_GOMC.'gomcDsn'
                
    $DSN_Name_POS = convertfrom-stringdata (get-content $instdirPath'\.install4j\response.varfile' -raw)
    $DSN_Name_POS =  $DSN_Name_POS.'posDsn'
    

    #return 
    $DSN_Name_GOMC
    $DSN_Name_POS
    $instdirPath       

} 

$resultInfoInstallGomcSuite = get-pathInstallGOMCSuite
if ($resultInfoInstallGomcSuite -is [array] ){
    $DSN_NameGOMC = $resultInfoInstallGomcSuite[0]
    $DSN_NamePOS = $resultInfoInstallGomcSuite[1]
    $pathInstall = $resultInfoInstallGomcSuite[2]
}

function get-pathInstallshield_x86{
    $keyInstallshield_x86 = 'HKLM:\SOFTWARE\WOW6432Node\OMC Gervais\Logiciels OMC Gervais'
    $keyIsPrensent = Test-Path $keyInstallshield_x86

    if ( $keyIsPrensent -eq "True"){
        
        $name0fRegisteryKey = 'install.targetdir'
        $instdirPath = (Get-ItemProperty -Path $keyInstallshield_x86).$name0fRegisteryKey
        
        if($instdirPath.Length -eq 0){
        
        }else{
            $DSN_NameGOMC = get-dataDirGOMCSuite_GOMC
            $DSN_NamePOS = get-dataDirGOMCSuite_POS
                        
            #return
            $DSN_NameGOMC
            $DSN_NamePOS
            $instdirPath
        }
        
    }
}

$resultInfoInstallInstallshield = get-pathInstallshield_x86
if ($resultInfoInstallInstallshield -is [array]){
    $DSN_NameGOMC = $resultInfoInstallInstallshield[0]
    $DSN_NamePOS = $resultInfoInstallInstallshield[1]
    $pathInstall = $resultInfoInstallInstallshield[2]
}

if ($DSN_NameGOMC.Length -gt 0){
    
    "----------------------------------------"
    "GOMC"
    "----------------------------------------"
    ODBCConnection -dsn "$DSN_NameGOMC;Uid=dba;Pwd=sql" -query "select dateformat(min(ticket.tic_chrono),'yyyy') as DateTicket from ticket"
}

if($DSN_NamePOS.Length -gt 0){
    
    ""
    "----------------------------------------"
    "POS"
    "----------------------------------------"
    ODBCConnection -dsn "$DSN_NamePOS;Uid=dba;Pwd=sql" -query "select dateformat(min(ticket.tic_chrono),'yyyy') as DateTicket from ticket"

}
Exit $LASTEXITCODE