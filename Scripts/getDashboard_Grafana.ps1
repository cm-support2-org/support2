$user = 'admin';
$pass = 'admomc83';
$port = '3000';
$server = 'rmm.cashmag.fr';
$outputPath = "$PSScriptRoot\output";
$outputFolderPath = "$([System.IO.Path]::Combine($outputPath,"001_Folder"))";
$outputDbPath = "$([System.IO.Path]::Combine($outputPath,"002_DB"))";
$outputDashboardPath = "$([System.IO.Path]::Combine($outputPath,"003_Dashboard"))";
$searchForAlarmsDashboards = $false;
$mainUrl = "https://$($server):$($port)";
Remove-Item -Path $outputPath -Recurse -ErrorAction SilentlyContinue;
New-Item -ItemType Directory -Force -Path $outputPath > $null;
if(-not $searchForAlarmsDashboards){
    New-Item -ItemType Directory -Force -Path $outputDbPath > $null;
    New-Item -ItemType Directory -Force -Path $outputFolderPath > $null;
}
$changelogStringBuilder = [System.Text.StringBuilder]::new();
$changelogStringBuilder.AppendLine("# $packageName") > $null;
$changelogStringBuilder.AppendLine("Package of all default grafana panels") > $null;
$changelogStringBuilder.AppendLine("") > $null;
$changelogStringBuilder.AppendLine("## [$nugetVersion] - $(Get-Date -format yyyy-MM-dd)") > $null;
$changelogStringBuilder.AppendLine("### Changed") > $null;
$changelogStringBuilder.AppendLine("- $nugetVersionReleaseNotes") > $null;
$changelogStringBuilder.AppendLine("### Added") > $null;
New-Item -ItemType Directory -Force -Path $outputDashboardPath > $null;
$Headers = @{
    Authorization = "Basic $([System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("$($user):$($pass)")))"
}
if(-not $searchForAlarmsDashboards){
    Write-Host "Getting folders";
    $folders = Invoke-RestMethod -Uri "$($mainUrl)/api/folders" -Method Get -Headers $Headers -ContentType 'application/json';
    $folders | % {
        $folder = New-Object System.Object;
        $folder | Add-Member -NotePropertyName uid -NotePropertyValue $_.uid;
        $folder | Add-Member -NotePropertyName title -NotePropertyValue $_.title;
        $folder | ConvertTo-Json | Out-File ([System.IO.Path]::Combine($outputFolderPath,"$($_.uid).folder"));
        $changelogStringBuilder.AppendLine("- Folder $($_.title)") > $null;
    }
    Write-Host "Getting Dbs";
    $dbs = Invoke-RestMethod -Uri "$($mainUrl)/api/datasources" -Method Get -Headers $Headers -ContentType 'application/json';
    $dbs | % {
        $db = New-Object System.Object;
        $db | Add-Member -NotePropertyName name -NotePropertyValue $_.name;
        $db | Add-Member -NotePropertyName uid -NotePropertyValue $_.uid;
        $db | ConvertTo-Json | Out-File ([System.IO.Path]::Combine($outputDbPath,"$($_.name).db"));
    }
}
Write-Host "Getting Dashboards";
$dashboards = Invoke-RestMethod -Uri "$($mainUrl)/api/search/?type=dash-db" -Method Get -Headers $Headers -ContentType 'application/json';
$dashboards | ? {($searchForAlarmsDashboards -and ($_.tags.Contains("alarms"))) -or (-not $searchForAlarmsDashboards -and (-not $_.tags.Contains("alarms")))} | % {
    $dashboard = Invoke-RestMethod -Uri "$($mainUrl)/api/dashboards/uid/$($_.uid)" -Method Get -Headers $Headers -ContentType "application/json";
    $changelogStringBuilder.AppendLine("- Dashboard slug: $($dashboard.meta.slug), updated: $($dashboard.meta.updated), updatedBy: $($dashboard.meta.updatedBy), version: $($dashboard.meta.version) uid: $($_.uid)") > $null;
	$dashboard | ConvertTo-Json -Depth 100 | Out-File ([System.IO.Path]::Combine($outputDashboardPath,"$($_.uid).json"));
}
Add-Content ([System.IO.Path]::Combine($outputPath,"changelog.txt")) $changelogStringBuilder.ToString();