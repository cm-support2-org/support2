<#
.Description
Verifie si un lot est recu en erreur directement du WebShop.
.NOTES
Change Log
#>
$ExitCode = 0
#Verification si le fichier existe. S'il existe pas creation
$fileToMessage = "$env:TEMP\CMErrorMessages.txt"
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
        $ExitCode = 99
  
    }
    
    #Execute query si connexion ok
    If ($opened -eq $true){
        
        $cmd = New-object System.Data.Odbc.OdbcCommand($query,$conn)
        $ds = New-Object system.Data.DataSet
        (New-Object system.Data.odbc.odbcDataAdapter($cmd)).fill($ds) | out-null
      
        $ds.Tables[0]
                
        if ($ds.Tables[0].Rows.Count -gt 0){
            $Message = "Des commandes en erreur sont presente !"
            $lbvalide = $false
            
            $ResultQuery = $ds.Tables[0]
            #Ecrire le message dans un fichier text           
            Add-Content $fileToMessage $Message 

            foreach ($Row in $ds.Tables[0].Rows) { 
                Add-Content $fileToMessage "---------------------------------------------------------------------------"	            
                Add-Content $fileToMessage "ID >>> $($Row.ID)"
                Add-Content $fileToMessage "DateCMD >>> $($Row.DateCmd)"
                Add-Content $fileToMessage "MessageErreur >>> $($Row.MessageErreur)"
	            Add-Content $fileToMessage "---------------------------------------------------------------------------"
            }
            
        }
        else
        {
        $Message = "Aucune commande en erreur"

        #Ecrire message
        Add-Content $fileToMessage $Message 
        $ExitCode = 0
        $lbvalide = $True                

        }                   
            
        #Fermeture de la connexion avec la base
        $conn.close()     

        if ($lbvalide -eq $false){
            $ExitCode = 1
        }
     
    } 
  
    exit $ExitCode
}

ODBCConnection -dsn "OMC_RESTAU;Uid=omc;Pwd=omc" -query "select xchglot_id as ID, xchglot_chrono as DateCmd, xchglot_message as MessageErreur from xchg_lot where xchglot_statut = 4"
