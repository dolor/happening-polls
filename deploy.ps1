# You may be required to enable script execution: Set-ExecutionPolicy Unrestricted -Scope CurrentUser
# Requires at least Powershell 3.0 (included since Windows 7)

$Src = (Split-Path $MyInvocation.MyCommand.Path) + "\"
$TmpDir = [System.IO.Path]::GetTempPath() + "\HappeningTmp\"
$Dest = [System.IO.Path]::GetTempFileName()

# Read key from first argument
if ($Args.length -eq 0) {
    echo "Usage: .\$($MyInvocation.MyCommand.Name) <upload key>"
    Exit
}

# Copy src directory to tmp
New-Item -Path $TmpDir -Type Directory
Copy-Item ($Src + "*") $TmpDir -recurse

# Create a ZIP file, remove old one first
If (Test-Path $Dest){
    Remove-Item $Dest
}

 try {
    [Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem")
    [System.IO.Compression.ZipFile]::CreateFromDirectory($TmpDir, $Dest, [System.IO.Compression.CompressionLevel]::Optimal, $false)
 } catch {
    echo "Unable to create a ZIP file. Aborting."
    Exit
 }

# Upload the file
# try {
   Invoke-RestMethod -Uri "https://happening.im/plugin/$($Args[0])" -InFile $Dest -Method POST
# } catch {
#     echo "Unable to post ZIP file. Is your key correct? Aborting."
#     remove-item $TmpDir -recurse
#     Exit
# }

remove-item $TmpDir -recurse
