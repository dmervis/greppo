$banner = @"     
  __ _  _ __   ___  _ __   _ __    ___  
 / _` || '__| / _ \| '_ \ | '_ \  / _ \ 
| (_| || |   |  __/| |_) || |_) || (_) |
 \__, ||_|    \___|| .__/ | .__/  \___/ 
 |___/             |_|    |_|          
"@

Write-Host $banner

do {
    $outputFile = $null
    $outputChoice = Read-Host "Do you want to output results to a file? (Y/N)"
    
    if ($outputChoice -eq "Y" -or $outputChoice -eq "y") {
        $fileType = Read-Host "Enter output file type (JSON/TXT)"
        $outputFile = Read-Host "Enter the output file path (including file name)"
        
        if ($fileType -eq "JSON") {
            $outputFile += ".json"
        } elseif ($fileType -eq "TXT") {
            $outputFile += ".txt"
        } else {
            Write-Host "Invalid file type. Results will not be saved." -ForegroundColor Red
            $outputFile = $null
        }
    }

    $pattern = Read-Host "Enter the search pattern"
    $folderPath = Read-Host "Enter the folder path"

    if (-not (Test-Path $folderPath)) {
        Write-Host "Folder not found: $folderPath" -ForegroundColor Red
        continue
    }

    $files = Get-ChildItem -Path $folderPath -Recurse -File
    if ($files.Count -eq 0) {
        Write-Host "No files found in the specified folder." -ForegroundColor Yellow
        continue
    }

    $results = $files | ForEach-Object {
        $matches = Get-Content $_.FullName | Select-String -Pattern $pattern -CaseSensitive:$false
        if ($matches) {
            [PSCustomObject]@{
                FileName    = $_.FullName
                MatchedLines = $matches
            }
        }
    } | Where-Object { $_ }

    if ($results) {
        if ($outputFile) {
            if ($fileType -eq "JSON") {
                $results | ConvertTo-Json | Out-File -FilePath $outputFile -Encoding utf8
                Write-Host "Results saved to $outputFile" -ForegroundColor Green
            } elseif ($fileType -eq "TXT") {
                $results | ForEach-Object {
                    Add-Content -Path $outputFile -Value "File: $($_.FileName)"
                    foreach ($line in $_.MatchedLines) {
                        Add-Content -Path $outputFile -Value "Matched Line: $($line.Line)"
                        Add-Content -Path $outputFile -Value "Line Number: $($line.LineNumber)"
                        Add-Content -Path $outputFile -Value "--------------------"
                    }
                }
                Write-Host "Results saved to $outputFile" -ForegroundColor Green
            }
        } else {
            foreach ($result in $results) {
                Write-Host "File: $($result.FileName)"
                foreach ($line in $result.MatchedLines) {
                    Write-Host "Matched Line: $($line.Line)" -ForegroundColor Green
                    Write-Host "Line Number: $($line.LineNumber)"
                    Write-Host "--------------------"
                }
            }
        }
    } else {
        Write-Host "No matches found for pattern: $pattern" -ForegroundColor Yellow
    }

    $choice = Read-Host "Do you want to perform another search? (Y/N)"
} while ($choice -eq "Y" -or $choice -eq "y")
