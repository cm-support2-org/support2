<#
.Description
Contole la date du plus ancien ticket. Selon l'annee du ticket une alerte est declencher pour inviter le service technique a effectuer une epuration.
.NOTES
Change Log
#>
$ExitCode = 0
#Verification si le fichier existe. S'il existe pas creation
$fileToMessage = "$env:TEMP\CMErrorDateTicket.txt"
$dateLotCMD = ""

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
  
    exit $ExitCode
}


#ODBCConnection -dsn "CM_POS;Uid=dba;Pwd=sql" -query "select dateformat(min(ticket.tic_chrono),'yyyy-mm') as DateTicket from ticket"
ODBCConnection -dsn "CM_POS;Uid=dba;Pwd=sql" -query "select min(ticket.tic_chrono) as DateTicket from ticket"
