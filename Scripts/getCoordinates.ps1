<#
.Description
Compte le nombre de lot present dans la base de donnes
.NOTES
Change Log
#>
$ExitCode = 0
#Verification si le fichier existe. S'il existe pas creation
$fileToMessage = "$env:TEMP\CMCountLotCMD.txt"
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
            #$lbvalide = $false
            
            $ResultQuery = $ds.Tables[0]
            #Ecrire le message dans un fichier text           
            Add-Content $fileToMessage $Message 

            foreach ($Row in $ds.Tables[0].Rows) {                 
                $adresse = $Row.adresse
                $codePostal =  $Row.codePostal
                $tiersId = $Row.tiersID #Id du tiers

                $webData = ConvertFrom-JSON (Invoke-WebRequest -uri "https://api-adresse.data.gouv.fr/search/?q=$adresse&postcode=$codePostal")

                $assets = $webData.features[0].geometry.coordinates

                write-output "$($assets[0])" #longitude
                write-output "$($assets[1])" #Latitude
                
            }
            #Ecrire message
        Add-Content $fileToMessage $Message 
        $ExitCode = 0
        $lbvalide = $True   
            
        }else{        

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
}

ODBCConnection -dsn "CM_GOMC;Uid=dba;Pwd=sql" -query "Select 
    replace(vue_tiers.mag_adresse,' ','+') as adresse, 
    vue_tiers.mag_codepostal as codePostal,
    vue_tiers.tie_id as tiersID
From 
    vue_tiers 
Where 
    vue_tiers.mag_adresse is not null"