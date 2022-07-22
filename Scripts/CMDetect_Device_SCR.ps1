$logFile = "C:\#Cashmag\log_"+(Get-Date).DayOfWeek.value__+".txt"

#Création d'un fichier de log 
if (Test-Path $logFile -PathType leaf){

}else{

    #Creation du fichier
    Set-Content $logFile ""

}

While($true)
    {
        
    #Si le fichier existe  
    $dateLogFile = Get-ChildItem -Path $logFile | Select-Object CreationTime 
   
    #Comparaison entre la date de la commande et la date de maintenant
    $tdiff = New-TimeSpan -Start (get-date $dateLogFile.CreationTime.toString("dd/MM/yyyy")) -End $(Get-Date -Format "dd/MM/yyyy")

     #Recuperation des differences
     $Nb_jours = $tdiff.TotalDays

    if ($Nb_jours -eq 0){
        
    }else{
        
        #Creation du fichier
        $logFile = "C:\#Cashmag\log_"+(Get-Date).DayOfWeek.value__+".txt"        
        Set-Content $logFile ""
    }

        #Verification si le scr est present
        if (Get-WmiObject -Class Win32_PnPEntity -Namespace "root\CIMV2" -Filter "PNPDeviceID like 'USB\\VID_0BED&PID_1100%'"){
            $getDate = Get-Date -Format "MM/dd/yyyy HH:mm:ss"         
            $message = $getDate + " >>> True"
            Add-Content $logFile $message

        }else{
            
            $getDate = Get-Date -Format "MM/dd/yyyy HH:mm:ss"         
            $message = $getDate + " >>> False"
            Add-Content $logFile $message
        }
    
        Start-Sleep -Milliseconds 1000
    }