<#
.Description
Verifie dans la table lot qu'aucun commande est recu en plusieurs exemplaire.
.NOTES
Change Log
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
                
                $dateLotCMD = $($Row.DateLot)                
                $today = $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                
                #Comparaison entre la date de la commande et la date de maintenant
                $tdiff = New-TimeSpan -Start $dateLotCMD -End $today
                
                #Recuperation des differences
                $Nb_jours = $tdiff.TotalDays
                $Nb_heures = $tdiff.TotalHours
                $Nb_minutes = $tdiff.TotalMinutes


                if ($Nb_jours -lt 1){

                Add-Content $fileToMessage "---------------------------------------------------------------------------"	            
                Add-Content $fileToMessage "Plusieurs commande recu avec le meme numero !"
                Add-Content $fileToMessage "ID >>> $($Row.IDLot)"
                Add-Content $fileToMessage "DateCMD >>> $($Row.DateLot)"
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

ODBCConnection -dsn "OMC_RESTAU;Uid=omc;Pwd=omc" -query "Select 
                                                                xchg_lot.xchglot_chrono as DateLot,
                                                                xchg_lot_commande.xchglot_id as IDLot
                                                            From    
                                                                    (SELECT 
    
                                                                    xchg_lot_commande.xchglotc_tic_uuid
    
                                                                FROM 
                                                                    xchg_lot, 
                                                                    xchg_lot_commande 
                                                                where 
                                                                    xchg_lot.xchglot_id = xchg_lot_commande.xchglot_id
                                                                Group by
                                                                    xchg_lot_commande.xchglotc_tic_uuid
    
                                                                Having 
                                                                    count(xchg_lot_commande.xchglotc_tic_uuid) > 10 ) as CmdDouble,
                                                                    xchg_lot_commande,
                                                                    xchg_lot

                                                            where 
                                                                xchg_lot_commande.xchglotc_tic_uuid = CmdDouble.xchglotc_tic_uuid and
                                                                xchg_lot.xchglot_id = xchg_lot_commande.xchglot_id
                                                        "
