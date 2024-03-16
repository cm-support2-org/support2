function Get-PathInstallGsuite {

    $registryPaths = @(
        "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\ej-technologies\install4j\installations",
        "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\ej-technologies\install4j\installations",
        "Registry::HKEY_CURRENT_USER\Software\ej-technologies\install4j\installations"
    )


    # Liste des noms de valeurs à rechercher
    #instdir6855-0348-7121-3187 = x64
    #instdir6281-3708-5137-9831 = x86
    $valueNames = @('instdir6855-0348-7121-3187', 
                    'instdir6281-3708-5137-9831')

    # Parcourir chaque chemin de registre
    foreach ($registryPath in $registryPaths) {

        # Vérifier si la clé de registre existe
        if (Test-Path $registryPath) {

            # Parcourir chaque nom de valeur
            foreach ($valueName in $valueNames) {

                # Obtenir la valeur de la chaîne spécifiée
                $value = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue

                if ($value) {
                    return $value.$valueName
                }
            }
        }
    }

    # Si aucune des clés n'existe, retourner une chaîne vide
    return ''
}

# Appeler la fonction pour obtenir le chemin d'installation de GOMCSuite
$resultpathInstallGsuite = Get-PathInstallGsuite
Write-Output $resultpathInstallGsuite