<#
.Description
Verifie si l'envoie des archive fiscal est active.
.NOTES
Change Log
#>
$ExitCode = 0
#Verification si le fichier existe. S'il existe pas creation
$fileToMessage = "$env:TEMP\CMCountLotCMD.txt"
$dateLotCMD = ""

if (Test-Path $fileToMessage -PathType leaf){
    #Si le fichier existe  
}else{
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
                
               $archivesUpload = $($Row.para_tax_archives_upldr)                
                                
               if ([string]::IsNullOrEmpty($archivesUpload)){
                    
                    $lbvalide = $false

                    Add-Content $fileToMessage "---------------------------------------------------------------------------"	            
                    Add-Content $fileToMessage "L'envoie des archives fiscal dans un compte Google drive n'est pas configure !"                
                    Add-Content $fileToMessage "---------------------------------------------------------------------------"

                }else{

                    Add-Content $fileToMessage "---------------------------------------------------------------------------"	            
                    Add-Content $fileToMessage "L'envoie des archives fiscal dans un compte Google drive est configure !"                    
	                Add-Content $fileToMessage "---------------------------------------------------------------------------"

                    #Ecrire message
                    Add-Content $fileToMessage $Message 
                    $ExitCode = 0
                    $lbvalide = $True                
                }            
            }            
        }                   
            
        #Fermeture de la connexion avec la base
        $conn.close()     

        if ($lbvalide -eq $false){
            $ExitCode = 1
        }     
    } 
  
    exit $ExitCode
}

ODBCConnection -dsn "OMC_RESTAU;Uid=dba;Pwd=sql" -query "select para_tax_archives_upldr from parametrage"
