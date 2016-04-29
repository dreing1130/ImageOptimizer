<#
.SYNOPSIS
Compress and optimize gif, png, and jpg images

.DESCRIPTION
Compress and optimize gif, png, and jpg images

.PARAMETER 
FolderPath
	The folder path to search.
Silent
	Flag to turn user interaction off

.PARAMETER FileExtension
The file extension to search for.

.EXAMPLE
PS> .\Get-FilesByExtension.ps1 -FolderPath 'C:\Windows' -FileExtension '.dll'
#>

param
(
	[parameter()][string] $FolderPath,
	[parameter()][switch] $Silent
)
$targetOriginalFile
$sourceFile
$targetOptimizedFile
$csvExists = Test-Path ".\ProcessedFiles.csv"
if(!$csvExists)
{
	echo "**Creating Processed Files csv**"
	New-Item -ItemType File -Path ".\ProcessedFiles.csv" -Force | Out-Null
	"Name,SavedOriginal" | out-file "ProcessedFiles.csv" -Encoding ASCII -append
}

$processedFiles = Import-Csv ".\ProcessedFiles.csv"
function CopyFile($file){
	$script:sourceFile = $file.FullName.SubString($script:FolderPath.Length);
	$script:targetOriginalFile = "$originalFileFolder" + $script:sourceFile; 
	New-Item -ItemType File -Path $script:targetOriginalFile -Force | Out-Null
	Copy-Item $file.FullName -Destination $script:targetOriginalFile -Force | Out-Null
	
	$script:targetOptimizedFile = "$optimizedFileFolder" + $script:sourceFile; 
	New-Item -ItemType File -Path $script:targetOptimizedFile -Force | Out-Null
	Copy-Item $file.FullName -Destination $script:targetOptimizedFile -Force | Out-Null
}
function OverwriteFile(){
	$originalFileSize = (Get-Item "$script:targetOriginalFile").length 
	$optimizedFileSize = (Get-Item "$script:targetOptimizedFile").length 
	if($Silent){
		$selectedFile = $script:targetOriginalFile
		if($originalFileSize -gt $optimizedFileSize){
			$selectedFile = $script:targetOptimizedFile
		}
		Copy-Item $selectedFile -Destination "$script:FolderPath$script:sourceFile" -Force | Out-Null	
	} else {
		echo "OriginalFile: $($originalFileSize)kb OptimizedFile: $($optimizedFileSize)kb"
		$answer = Read-Host "Use Optimized File? Yes (y) or No (n)"
		while(("yes","no" -notcontains $answer) -and ("y" -eq $answer) -and ("n" -eq $answer))
		{
			$answer = Read-Host "Respond Yes (y) or No (n)"
		}
		$selectedFile = $script:targetOriginalFile
		if(($answer -eq "yes") -or ($answer -eq "y")){
			$selectedFile = $script:targetOptimizedFile
		}
		Copy-Item $selectedFile -Destination "$script:FolderPath$script:sourceFile" -Force | Out-Null		
	}
	"$script:FolderPath$script:sourceFile,$originalFileFolder" | out-file "ProcessedFiles.csv" -Encoding ASCII -append
}

echo "*********************************************"
echo "****************STARTING*********************"
echo "*********************************************"
$oldDirectoryExists = Test-Path '.\optimized'
if($oldDirectoryExists)
{
	echo "**Removing old folder structures**"
	%{Remove-Item '.\optimized\*' -recurse}
}
echo "**Setting up folder structures**"
$timeStamp = get-date -Format FileDateTimeUniversal
$originalFileFolder = New-Item -ItemType Directory -Force -Path ".\original$timeStamp"
echo "**Original Folder Backup: $originalFileFolder**"
$optimizedFileFolder = New-Item -ItemType Directory -Force -Path ".\optimized$timeStamp"
echo "**Optimized Folder Backup: $optimizedFileFolder**"
$targetFiles = get-childitem $FolderPath -Recurse
echo "**Creating Image lists**"
$pngList = $targetFiles | where {$_.extension -eq '.png'}
$jpgList = $targetFiles | where {$_.extension -eq '.jpg'}
$gifList = $targetFiles | where {$_.extension -eq '.gif'}

echo "*********************************************"
echo "**Processing PNGs**"
foreach ($pngFile in $pngList) {
	$fileAlreadyProcessed = $processedFiles | Where-Object {$_.name -eq $pngFile.FullName}
	if($fileAlreadyProcessed.length -eq 0)
	{
		CopyFile($pngFile)
		
		%{.\pngcrush.exe -brute -l 9 -q -force -ow "$targetOptimizedFile"}
		
		OverwriteFile
		echo "**File Processed**"
	}
}

echo "*********************************************"
echo "**Processing JPGs**"
foreach ($jpgFile in $jpgList) {
	$fileAlreadyProcessed = $processedFiles | Where-Object {$_.name -eq $jpgFile.FullName}
	if($fileAlreadyProcessed.length -eq 0)
	{
		CopyFile($jpgFile)
		
		%{.\jpegoptim.exe -f -m 90 -o -q --all-progressive --strip-all --strip-iptc --strip-icc "$targetOptimizedFile"}
		
		OverwriteFile
		echo "**File Processed**"
	}	
}
echo "*********************************************"
echo "**Processing Gifs**"
foreach ($gifFile in $gifList) {
	$fileAlreadyProcessed = $processedFiles | Where-Object {$_.name -eq $gifFile.FullName}
	if($fileAlreadyProcessed.length -eq 0)
	{
		CopyFile($gifFile)
		
		%{.\gifsicle.exe -O3 -o "$targetOptimizedFile" "$targetOptimizedFile"}
		
		OverwriteFile
		echo "**File Processed**"
	}		
}
echo "*********************************************"
echo "****************COMPLETED********************"
echo "*********************************************"