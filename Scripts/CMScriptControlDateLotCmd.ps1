<#
.Description
Verifie qu'aucune commande reste bloque (statut 1 ) pendant un certain temps.
.NOTES
Change Log
21-06-2021
    -   #slu: Ajout de l'arrondi pour le nombre de jour, d'heure et de minutes. 
    -   #slu: Ajout du message d'erreur du lot.
#>
$ExitCode = 0
#Verification si le fichier existe. S'il existe pas creation
$fileToMessage = "$env:TEMP\CMErrorDateLotCMD.txt"
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
        $ExitCode = 99
  
    }
    
    #Execute query si connexion ok
    If ($opened -eq $true){
        
        $cmd = New-object System.Data.Odbc.OdbcCommand($query,$conn)
        $ds = New-Object system.Data.DataSet
        (New-Object system.Data.odbc.odbcDataAdapter($cmd)).fill($ds) | out-null
      
        $ds.Tables[0]
                
        if ($ds.Tables[0].Rows.Count -gt 0){
            $lbvalide = $false
            
            $ResultQuery = $ds.Tables[0]

            #Ecrire le message dans un fichier text           
            Add-Content $fileToMessage $Message 

            foreach ($Row in $ds.Tables[0].Rows) { 
                
                $dateLotCMD = $($Row.DateCmd)                
                $today = $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                
                #Comparaison entre la date de la commande et la date de maintenant
                $tdiff = New-TimeSpan -Start $dateLotCMD -End $today
                
                #Recuperation des differences
                $Nb_jours = $tdiff.TotalDays
                $Nb_heures = $tdiff.TotalHours
                $Nb_minutes = $tdiff.TotalMinutes

                #round du nombre de jours
                $Nb_jours = [math]::Round(($Nb_jours),0)     

                #round du nombe d'heures
                $Nb_heures = [math]::Round(($Nb_heures),0)     

                #round du nombe de minutes
                $Nb_minutes = [math]::Round(($Nb_minutes),0)     

                if ($Nb_minutes -gt 30){

                Add-Content $fileToMessage "---------------------------------------------------------------------------"	            
                Add-Content $fileToMessage "Les commandes ci-dessous sont bloquee depuis $Nb_jours jour(s) - $Nb_heures heure(s) - $Nb_minutes minute(s) !"
                Add-Content $fileToMessage "ID >>> $($Row.ID)"
                Add-Content $fileToMessage "DateCMD >>> $($Row.DateCmd)"
                Add-Content $fileToMessage "Message d'erreur >>> $($Row.MessageCmd)"
	            Add-Content $fileToMessage "---------------------------------------------------------------------------"

                }
            
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

ODBCConnection -dsn "OMC_RESTAU;Uid=dba;Pwd=sql" -query "Select 
                                                            xchglot_id as ID, 
                                                            xchglot_chrono as DateCmd,
                                                            xchglot_message as MessageCmd
                                                         From 
                                                            xchg_lot 
                                                         Where 
                                                            xchglot_statut = 1
                                                         "
