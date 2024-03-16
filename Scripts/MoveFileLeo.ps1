#***************************************************************
#17/02/2023
#Depuis la version 2.52.095.041 de Leo les fichiers Histo_j et Reglem_j
#qui permet la remontées des chiffres dans GOMC ne sont plus #au meme endroit.
#Avant "C:\atoo_leo250\data\histo\" Maintenant "C:\atoo_leo250\histoJour"
#Le script deplace les fichiers du nouveau repertoire vers l'ancien.
#***************************************************************
Clear-Host

function copyHisto_j {
    param($dateMostRecentFile)
    # Définir le chemin d'accès du dossier racine
    $dossierRacine = "C:\atoo_leo250\histoJour"

    # Définir le filtre de nom de fichier
    $filtre = "Histo_j*.FIC"

    # Obtenir la liste des fichiers dans les sous-dossiers qui ont été modifiés après la date minimale et qui correspondent au filtre de nom de fichier
    #$listeFichiers = Get-ChildItem -Path $dossierRacine -Recurse -File -Filter $filtre | Where-Object { $_.LastWriteTime -gt $dateMostRecentFile }
    $listeFichiers = Get-ChildItem -Path $dossierRacine -Recurse | Where-Object { !$_.PSIsContainer -and $_.Name -like $filtre -and $_.LastWriteTime -gt $dateMostRecentFile }

    # Vérifier si des fichiers ont été trouvés
    if ($listeFichiers.Count -eq 0) {
        #Write-Host "Aucun fichier trouvé dans les sous-dossiers de $dossierRacine modifié après $dateMin avec le filtre $filtre."
    } else {
        # Afficher les noms et les dates de modification des fichiers trouvés
        #Write-Host "Les fichiers modifiés après $dateMin dans les sous-dossiers de $dossierRacine avec le filtre $filtre sont :"
        $listeFichiers | ForEach-Object { Write-Host "- $($_.Name)" }
        
        #Copy file
        Copy-Item -Path $listeFichiers.FullName -Destination "C:\atoo_leo250\data\histo" -Force

    }
}

function copyReglem_j {
    param($dateMostRecentFile)

     # Définir le chemin d'accès du dossier racine
     $dossierRacine = "C:\atoo_leo250\histoJour"

     # Définir le filtre de nom de fichier
     $filtre = "Reglem_j*.FIC"

     # Obtenir la liste des fichiers dans les sous-dossiers qui ont été modifiés après la date minimale et qui correspondent au filtre de nom de fichier
     #$listeFichiers = Get-ChildItem -Path $dossierRacine -Recurse -File -Filter $filtre | Where-Object { $_.LastWriteTime -gt $dateMostRecentFile }
     $listeFichiers = Get-ChildItem -Path $dossierRacine -Recurse | Where-Object { !$_.PSIsContainer -and $_.Name -like $filtre -and $_.LastWriteTime -gt $dateMostRecentFile }

 
     # Vérifier si des fichiers ont été trouvés
     if ($listeFichiers.Count -eq 0) {
         #Write-Host "Aucun fichier trouvé dans les sous-dossiers de $dossierRacine modifié après $dateMin avec le filtre $filtre."
     } else {
         # Afficher les noms et les dates de modification des fichiers trouvés
     # Write-Host "Les fichiers modifiés après $dateMin dans les sous-dossiers de $dossierRacine avec le filtre $filtre sont :"
         $listeFichiers | ForEach-Object { Write-Host "- $($_.Name), modifié le $($_.LastWriteTime)." }
         
         #Copy file
         Copy-Item -Path $listeFichiers.FullName -Destination "C:\atoo_leo250\data\histo" -Force
 
     }
}

#------------------------------------------------------------------------------------------------------------------
#Fichier Histo_j
#------------------------------------------------------------------------------------------------------------------

# Définir le chemin d'accès du répertoire
$chemin = "C:\atoo_leo250\data\histo\"

# Définir le filtre de nom de fichier
$filtre = "Histo_j*"

# Obtenir la liste des fichiers triés par date de modification
$listeFichiers = Get-ChildItem -Path $chemin -Filter $filtre | Sort-Object LastWriteTime -Descending

# Vérifier si des fichiers ont été trouvés
if ($listeFichiers.Count -eq 0) {
    $dateMostRecentFile = Get-Date "2000-01-01 00:00:00"
    copyHisto_j "$dateMostRecentFile"

} else {
    # Afficher le nom et la date de modification du fichier le plus récent
    $fichierPlusRecent = $listeFichiers[0]
    #Write-Host "Le fichier le plus récent dans le répertoire $chemin avec le filtre $filtre est $($fichierPlusRecent.Name), modifié le $($fichierPlusRecent.LastWriteTime)."
    $dateMostRecentFile = $fichierPlusRecent.LastWriteTime

    #Write-Host $dateMostRecentFile   
    copyHisto_j "$dateMostRecentFile"
    
}
#------------------------------------------------------------------------------------------------------------------
#Fichier Reglem_j
#------------------------------------------------------------------------------------------------------------------

# Définir le chemin d'accès du répertoire
$chemin = "C:\atoo_leo250\data\histo"

# Définir le filtre de nom de fichier
$filtre = "Reglem_j*"

# Obtenir la liste des fichiers triés par date de modification
$listeFichiers = Get-ChildItem -Path $chemin -Filter $filtre | Sort-Object LastWriteTime -Descending

# Vérifier si des fichiers ont été trouvés
if ($listeFichiers.Count -eq 0) {

    $dateMostRecentFile = Get-Date "2000-01-01 00:00:00"
    copyReglem_j "$dateMostRecentFile"

} else {
    # Afficher le nom et la date de modification du fichier le plus récent
    $fichierPlusRecent = $listeFichiers[0]
    #Write-Host "Le fichier le plus récent dans le répertoire $chemin avec le filtre $filtre est $($fichierPlusRecent.Name), modifié le $($fichierPlusRecent.LastWriteTime)."
    $dateMostRecentFile = $fichierPlusRecent.LastWriteTime
    #Write-Host $dateMostRecentFile

    copyReglem_j "$dateMostRecentFile"
}