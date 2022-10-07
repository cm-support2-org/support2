Get-ChildItem "C:\Users\slu\Documents\GitHub\support2\Scripts\output\003_Dashboard" -Filter *.json | 

Foreach-Object {
    $content =  $_.Name    
    $magCodeClient = ''
    if ($content -eq 'niXIQBVVk.json' ){
        $magCodeClient = 'Mag5080'
        
    }elseif ($content -eq 'niXIQBVVq.json' ){
        $magCodeClient = 'Mag172799'
        
    }elseif ($content -eq 'niXIQBVVd.json' ){
        $magCodeClient = 'MagBacSable'
        
    }
    
    (Get-Content "C:\Users\slu\Documents\GitHub\support2\Scripts\output\003_Dashboard\niXIQBVVd.json") -Replace 'MagBacSable', $magCodeClient | Set-Content "G:\Tmp\grafana\$content"
}