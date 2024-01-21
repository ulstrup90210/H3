# Set variables for start time of the script
$StartTime = Get-Date

# Set variables for the Json File URL and the download directory
$JsonUrl = "https://raw.githubusercontent.com/Koenkk/zigbee-OTA/master/index.json"

$DownloadDirectory = "\\192.168.50.50\config\zha_ota\"

# Get the Json File and convert it to a PowerShell object
$Json = Invoke-RestMethod -Uri $JsonUrl

# Get a list of all the URLs from the Json File
$UrlList = $Json.url

# This line counts the number of files that do not exist in the specified download directory by filtering a list of URLs
$TotalFiles = ($UrlList | Where-Object { -not (Test-Path -Path "$DownloadDirectory\$($_.Split("/")[-1])") }).Count

$FilesDownloaded = 0
$FilesSkipped = 0
$FilesDeleted = 0


# Arrays to store the downloaded and deleted filenames
$DownloadedFiles = @()
$DeletedFiles = @()

# Loop through each URL in the list
foreach ($url in $UrlList) {
    $FileName = $url.Split("/")[-1] # Extract the filename from the URL

    # Check if the File already exists in the download directory
    if (Test-Path -Path "$DownloadDirectory\$FileName") {
        Write-Host "[SKIPPED] $FileName already exists, skipping..."
        $FilesSkipped++
    }
    else {
        # Download the File and save it to the download directory
        Invoke-WebRequest -Uri $url -OutFile "$DownloadDirectory\$FileName"
        Write-Host "[DOWNLOAD] Downloading File $($FilesDownloaded+1) of $($TotalFiles): $($FileName)" -ForegroundColor Green
        $FilesDownloaded++

        # Add the downloaded filename to the array
        $DownloadedFiles += $FileName
    }
}

# Get a list of all the files in the download directory
$downloadedFilesList = Get-ChildItem -Path $DownloadDirectory -File

# Loop through each File in the directory
foreach ($File in $downloadedFilesList) {
    $FileName = $File.Name

    # Check if the File is in the Json File
    $FileExists = $UrlList -like "*$FileName"

    if ($FileExists) {
        Write-Host "$FileName exists in the Json File, skipping..."
    }
    else {
        # Delete the File from the download directory
        Write-Host "[Delete] Deleting $FileName..." -ForegroundColor Red
        Remove-Item -Path "$DownloadDirectory\$FileName" -Force
        $FilesDeleted++

        # Add the deleted filename to the array
        $DeletedFiles += $FileName
    }
}

# These two lines of code calculate the elapsed time between the start of the script execution and the end of the script execution.
$EndTime= Get-Date
$ElapsedTime = New-TimeSpan -Start $StartTime -End $EndTime

# Outputs final status
Write-Host "`nDone - Time elapsed: $($ElapsedTime.ToString("hh\:mm\:ss"))"
Write-Host "Total files downloaded: $FilesDownloaded"
Write-Host "Total files skipped: $FilesSkipped"
Write-Host "Total files deleted: $FilesDeleted"

# Output the downloaded and deleted filenames
Write-Host "`nDownloaded files:`n$($DownloadedFiles -join "`n")`n" -ForegroundColor Green
Write-Host "Deleted files:`n$($DeletedFiles -join "`n")`n" -ForegroundColor Red
