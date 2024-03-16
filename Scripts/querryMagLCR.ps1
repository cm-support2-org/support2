# Définir la liste des magasins avec codes et noms
$magasins = @{
    '1' = 'Charlville'
    '2' = 'CORBEIL'
    '3' = 'DAVIEAU'
    '4' = 'ECLIPSE'
    '5' = 'ELYSO'
    '6' = 'GOPIN'
    '7' = 'Grenoble'
    '8' = 'LATESTE'
    '9' = 'ORLY'
    '10' = 'Osny'
    '11' = 'PARKS'
    '12' = 'PESSAC'
    '13' = 'PianMedoc'
    '14' = 'RC_Bordo'
    '15' = 'St_Aunes'
    '16' = 'Torcy'
    '17' = 'Valentine'      
}

# Définir la liste des actions
$actions = @{
    '1' = 'Deflag Ticket'
}

# Trier les magasins par code
$magasins = $magasins.GetEnumerator() | Sort-Object -Property Value | ConvertTo-Hashtable

# Trier les actions par code
$actions = $actions.GetEnumerator() | Sort-Object -Property @{Expression={$_.Key}; Ascending=$true} -AsHashTable

# Afficher la liste des magasins à l'utilisateur
$selectedMagasin = $magasins.GetEnumerator() | Out-GridView -Title "Sélectionnez un magasin" -OutputMode Single

# Obtenir la taille de l'écran
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea

# Calculer les nouvelles coordonnées pour centrer la fenêtre
$newX = [math]::Max(0, ($screen.Width - $selectedMagasin.Width) / 5)
$newY = [math]::Max(0, ($screen.Height - $selectedMagasin.Height) / 5)

# Déplacer la fenêtre vers le centre
$selectedMagasin.StartPosition = 'Center'
$selectedMagasin.Location = New-Object System.Drawing.Point($newX, $newY)

# Vérifier si l'utilisateur a fait une sélection
if ($selectedMagasin) {
    # Récupérer le code du magasin sélectionné
    $selectedCode = $selectedMagasin.Key

    # Récupérer le nom du magasin sélectionné
    $selectedNom = $selectedMagasin.Value

    # Afficher les détails de la sélection
    Write-Output "Magasin sélectionné :"
    Write-Output "Code : $selectedCode"
    Write-Output "Nom : $selectedNom"
} else {
    Write-Output "Aucun magasin sélectionné."
}

# Afficher la liste des actions et obtenir la sélection de l'utilisateur
$actionSelection = $actions.GetEnumerator() | Out-GridView -Title 'Sélectionnez une action' -OutputMode Single

# Vérifier si l'action sélectionnée est "Deflag Ticket"
if ($actionSelection.Key -eq '1') {
    # Charger l'assembly pour Windows Forms
    Add-Type -AssemblyName System.Windows.Forms

    # Créer un formulaire Windows Forms
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Choix des dates"
    $form.Size = New-Object System.Drawing.Size(300, 200)

    # Créer un label pour indiquer date de début
    $labelDebut = New-Object System.Windows.Forms.Label
    $labelDebut.Location = New-Object System.Drawing.Point(20, 0)
    $labelDebut.Margin = '0,0,0,50'  # Ajouter une marge de 10 pixels en bas
    $labelDebut.Text = "Date Début:"
    $form.Controls.Add($labelDebut)

    # Créer un DateTimePicker pour la date de début
    $datePickerDebut = New-Object System.Windows.Forms.DateTimePicker
    $datePickerDebut.Location = New-Object System.Drawing.Point(20, 20)
    $datePickerDebut.Format = [System.Windows.Forms.DateTimePickerFormat]::Custom
    $datePickerDebut.Padding = '150,150,150,150'  # Ajouter une marge de 10 pixels en bas
    $datePickerDebut.CustomFormat = 'yyyy-MM-dd HH:mm'
    $form.Controls.Add($datePickerDebut)

    # Créer un label pour indiquer date de début
    $labelFin = New-Object System.Windows.Forms.Label
    $labelFin.Location = New-Object System.Drawing.Point(20, 0)
    $labelFin.Margin = '0,0,0,50'  # Ajouter une marge de 10 pixels en bas
    $labelFin.Text = "Date Fin:"
    $form.Controls.Add($labelFin)

    # Créer un DateTimePicker pour la date de fin
    $datePickerFin = New-Object System.Windows.Forms.DateTimePicker
    $datePickerFin.Location = New-Object System.Drawing.Point(20, 60)
    $datePickerFin.Format = [System.Windows.Forms.DateTimePickerFormat]::Custom
    $datePickerDebut.Padding = '150,150,150,150'  # Ajouter une marge de 10 pixels en bas
    $datePickerFin.CustomFormat = 'yyyy-MM-dd HH:mm'
    $form.Controls.Add($datePickerFin)

    # Créer un bouton OK pour fermer le formulaire
    $buttonOK = New-Object System.Windows.Forms.Button
    $buttonOK.Location = New-Object System.Drawing.Point(20, 100)
    $buttonOK.Text = "OK"
    $buttonOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($buttonOK)

    # Afficher le formulaire et attendre la fermeture
    $result = $form.ShowDialog()

    # Si l'utilisateur a cliqué sur OK, afficher les dates sélectionnées
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $dateDebut = $datePickerDebut.Value.ToString('yyyy-MM-dd HH:mm:ss')
        $dateFin = $datePickerFin.Value.ToString('yyyy-MM-dd HH:mm:ss')

        Write-Output "Dates sélectionnées :"
        Write-Output "Date de début : $dateDebut"
        Write-Output "Date de fin : $dateFin"

       # Supposons que $dateDebut et $dateFin sont des variables avec les valeurs appropriées

       $dataSourceName = ""

       if ($selectedMagasin.Key -eq 1){
            $dataSourceName = "CM_CHARLEVILLE"

        elseif ($selectedMagasin.Key -eq 2) {
            $dataSourceName = "CM_CORBEIL"
        }            
        elseif ($selectedMagasin.Key -eq 3) {
            $dataSourceName = "CM_DAVIEAU"            
        }            
        elseif ($selectedMagasin.Key -eq 4) {
            $dataSourceName = "CM_ECLIPSE"   
        }                                             
        elseif ($selectedMagasin.Key -eq 5) {
            $dataSourceName = "CM_ELYSO"     
        }                               
        elseif ($selectedMagasin.Key -eq 6) {
            $dataSourceName = "CM_GOPIN"                                                
        }
        elseif ($selectedMagasin.Key -eq 7) {
            $dataSourceName = "CM_Grenoble"                                                
        }
        elseif ($selectedMagasin.Key -eq 8) {
            $dataSourceName = "CM_LATESTE"                                                
        }
        elseif ($selectedMagasin.Key -eq 9) {
            $dataSourceName = "CM_ORLY"                                                
        }
        elseif ($selectedMagasin.Key -eq 10) {
            $dataSourceName = "CM_Osny"                                                
        }
        elseif ($selectedMagasin.Key -eq 11) {
            $dataSourceName = "CM_PARKS"                                                
        }
        elseif ($selectedMagasin.Key -eq 12) {
            $dataSourceName = "CM_PESSAC"                                                
        }
        elseif ($selectedMagasin.Key -eq 13) {
            $dataSourceName = "CM_PianMedoc"                                                
        }
        elseif ($selectedMagasin.Key -eq 14) {
            $dataSourceName = "CM_RC_Bordo"                                                
        }
        elseif ($selectedMagasin.Key -eq 15) {
            $dataSourceName = "CM_St_Aunes"                                                
        }
        elseif ($selectedMagasin.Key -eq 16) {
            $dataSourceName = "CM_Torcy"                                                
        }
        elseif ($selectedMagasin.Key -eq 17) {
            $dataSourceName = "CM_Valentine"                                                
        }
       }

# Spécifiez votre chaîne de connexion ODBC
$connectionString = "DSN=$dataSourceName;uid=omc;pwd=omc;"

# Créez une connexion ODBC
$connection = New-Object System.Data.Odbc.OdbcConnection
$connection.ConnectionString = $connectionString

try {
    # Ouvrez la connexion
    $connection.Open()

    $sqlCommand = @"
        UPDATE detail_ticket
        SET detail_ticket.dtic_facture_1 = 0
        FROM ticket
        WHERE ticket.tic_id = detail_ticket.tic_id
        AND ticket.tic_publisher = detail_ticket.tic_publisher
        AND ticket.tic_chrono > '$dateDebut'
        AND ticket.tic_chrono < '$dateFin'
"@

    # Exécutez la commande
    $command = $connection.CreateCommand()
    $command.CommandText = $sqlCommand
    $rowsAffected = $command.ExecuteNonQuery()

    [System.Windows.Forms.MessageBox]::Show("$rowsAffected lignes affectées.")

} finally {
    # Fermez la connexion, même en cas d'erreur
    $connection.Close()
}

    } else {
        Write-Output "Opération annulée."
    }
}
else {
    # Si une autre action est choisie, afficher simplement l'action sélectionnée
    Write-Output "Action sélectionnée : $actionSelection"
}