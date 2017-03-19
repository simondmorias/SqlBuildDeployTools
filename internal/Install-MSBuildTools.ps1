Function Install-MsBuildTools
{
    $DownloadPath = Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads"
    $url = "https://download.microsoft.com/download/E/E/D/EEDF18A8-4AED-4CE0-BEBE-70A83094FC5A/BuildTools_Full.exe"
    $BuildToolsExe = "$DownloadPath\BuildTools_Full.exe"
    Invoke-WebRequest $url -OutFile $BuildToolsExe
    Start-Process -Wait $BuildToolsExe -ArgumentList -quiet
    Remove-Item $BuildToolsExe

    $MSBuildPath = "${env:ProgramFiles(x86)}\MSBuild\14.0\Bin\MSBuild.exe"
    if(! (Test-Path $MSBuildPath))
    {
        Write-Error "MSBuildTools failed to install"
    }

    if(! (Test-Path $BuildToolsExe))
    {
        Write-Error "Failed to cleanup downloaded files at $BuildToolsExe"
    }
}