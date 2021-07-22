<#
.Description
Compte le nombre de ticket present dans la base de donnes
.NOTES
Change Log
#>
$ExitCode = 0
#Verification si le fichier existe. S'il existe pas creation
$fileToMessage = "$env:TEMP\CMCountTicket.txt"
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
                Add-Content $fileToMessage $Row.countTicket
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
  
    exit $ExitCode
}


$query = "select count(*) as countTicket from ticket"

If (Get-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\ODBC\ODBC.ini\OMC_RESTAU_SECOURS"  -Name Description -ErrorAction SilentlyContinue) {
     
#Write-Output "found"
ODBCConnection -dsn "OMC_RESTAU_SECOURS;Uid=dba;Pwd=sql" -query $query

}Elseif (Get-ItemProperty -Path "HKLM:\SOFTWARE\ODBC\ODBC.ini\OMC_RESTAU_SECOURS"  -Name Description -ErrorAction SilentlyContinue){

#Write-Output "not found"
ODBCConnection -dsn "OMC_RESTAU_SECOURS;Uid=dba;Pwd=sql" -query $query


}Elseif (Get-ItemProperty -Path "HKLM:\SOFTWARE\ODBC\ODBC.ini\OMC_RESTAU"  -Name Description -ErrorAction SilentlyContinue){

#Write-Output "not found"
ODBCConnection -dsn "OMC_RESTAU;Uid=dba;Pwd=sql" -query $query

}Elseif (Get-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\ODBC\ODBC.ini\OMC_RESTAU"  -Name Description -ErrorAction SilentlyContinue){

#Write-Output "not found"
ODBCConnection -dsn "OMC_RESTAU;Uid=dba;Pwd=sql" -query $query
}
