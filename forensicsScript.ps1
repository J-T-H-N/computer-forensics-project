##############################
# POWERSHELL SCRIPT
# 
# Authors: Alexandra Ioannidis
#	   Jathan Anandham
#
##############################

# make sure to create section titles in report (ex. YARA, General Process Information)

Write-Output "Beginning reporting process..."

# GENERAL INFORMATION

# Get current date (ISO Compliant) for report title 
$titleDate=Get-Date -format yyyy_MM_dd
$text = $titleDate + '_Report.txt'

# Get current user's Desktop path
$desktopPath=[Environment]::GetFolderPath("Desktop")

# Create a reports directory for report files if non existent
$path = $desktopPath + '\Windows Artifact Reports'
if(!(test-path $path)){ New-Item -ItemType Directory -Force -Path $path}
New-Item -Path $path -Name $text -ItemType "file" 

$title="WINDOWS ARTIFACTS REPORT"
$title | Out-File "$path\$text" -Append

# Get current date/time for report
$time=Get-Date
$time.ToUniversalTime()
$time | Out-File "$path\$text" -Append

# Get name of machine
$compName="Computer Name: " + $env:computername
$compName | Out-File "$path\$text" -Append

Write-Output "Beginning YARA analysis..."
$yarasection="`nYARA: "
$yarasection | Out-File "$path\$text" -Append

# Display the count of anomalies that YARA found in Report and the number of files it scanned?
$childCount=0
Get-ChildItem -Recurse -filter *.exe C:\ 2> $null |
ForEach-Object { Write-Host -foregroundcolor "green" "Scanning"$_.FullName $_.Name; $childCount+=1; ./yara64.exe -d filename=$_.Name TOOLKIT.yar $_.FullName 2> $path\$text }

$yarafileCount="Number of files scanned: " + $childCount.Count
$yarafileCount | Out-File "$path\$text" -Append

Write-Output "Beginning Processes Section..."

# PROCESSES
$processArray=Get-Process | Select-Object -Property Id, ProcessName, Path
$processPath=Get-Process | Select-Object -Property Path
$procCount= "Number of current processes: " + $processArray.Count
$current="CURRENT PROCESSES:"
$current | Out-File "$path\$text" -Append

$nullCount=0
foreach ($proc in get-process)
    {
    try
        {
        $hashtable= Get-FileHash $proc.path -Algorithm SHA1 -ErrorAction stop
        }
    catch
        {
         #error handling... log contains names of processes where there was no path listed or we lack the rights
         $nullCount+=1
        }
    }

#foreach ( $row1 in $processArray ) {
#  foreach ( $row2 in $hashtable ) {
#    if ( $row1.ID -eq $row2.ID ) {
  # BEGIN CALLOUT A
#  $newtable= New-Object PSCustomObject -Property @{
#    "ID" = $row1.ID
#    "ProcessName" = $row1.ProcessName
#    "SHA1 Hash" = $row2.Hash
#    "Path" = $row1.Path
#  } | Select-Object ID,ProcessName,Hash,Path
  # END CALLOUT A
#    }
#  }
#}



$processArray | Out-File "$path\$text" -Append
$procCount | Out-File "$path\$text" -Append

$startup=Get-CimInstance win32_service -Filter "startmode = 'auto'" | Select-Object ProcessId, Name
$autoCount = "Number of Start-Up Processes: " + $startup.Count
$start="STAR"
$startup | Out-File "$path\$text" -Append
$autoCount | Out-File "$path\$text" -Append

# SERVICES
$running = Get-Service | where {$_.status -eq 'running'}
$runCount = "Number of Running Services: " + $running.Count
$running | Out-File "$path\$text" -Append
$runCount | Out-File "$path\$text" -Append
$stopped = Get-Service | where {$_.status -eq 'stopped'}
$stopCount = "Number of Stopped Services: " + $stopped.Count
$stopCount | Out-File "$path\$text" -Append

Write-Output "Reporting Process Finished..."

$emailChoice= Read-Host -Prompt "Do you want to send report as email attachment? (Enter Y for Yes or N for No): "
if ($emailChoice -eq 'Y' -OR $emailChoice -eq 'y' -OR $emailChoice -eq 'yes' -OR $emailChoice -eq 'Yes'){
     $userFrom=Read-Host -Prompt "Enter the email of the sender: "
     $userTo=Read-Host -Prompt "Enter the email of the receiver in: "
     Send-MailMessage -From "<$userFrom>" -To "<$userTo>" -Subject "Windows Artifact Report" -Body "Windows Artifact Report" -Attachments "$path\$text" -dno onSuccess, onFailure
}

