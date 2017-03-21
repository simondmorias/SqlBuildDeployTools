Function Install-MsBuild
{
    [cmdletbinding()]
    param (
        [string]$Url = "https://download.microsoft.com/download/E/E/D/EEDF18A8-4AED-4CE0-BEBE-70A83094FC5A/BuildTools_Full.exe",
        [string]$version = "14.0",
        [switch]$Force
    )

    if(! (Test-PSUserIsAdmin))
    {
        throw "This command must be run as Administrator"
    }    
    $DownloadPath = Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads"    
    $BuildToolsExe = Join-Path $DownloadPath "BuildTools_Full.exe"
    $MSBuildPath = Join-Path $env:ProgramFiles(x86) "MSBuild\$version\Bin\MSBuild.exe"
    $SkipDownload = $false
    $SkipInstall = $false
    
    if (Test-Path $BuildToolsExe)
    {
        if($Force)
        {
            Write-Warning "MSBuildTools has already been downloaded. Overwriting..."
        } else {
            Write-Warning "$BuildToolsExe already exists."
            $SkipDownload = $true
        }    
    }
    if ($SkipDownload -ne $true)
    {
        try 
        {
            Write-Verbose "Downloading MSBuildTools to $BuildToolsExe"
            Invoke-WebRequest $url -OutFile $BuildToolsExe -TimeoutSec 20
        }
        catch [System.Net.WebException]
        {
            Write-Warning "Do you have internet connection?"
            throw            
        }
    }
    
    if(Test-Path $MSBuildPath)
    {
        if($Force)
        {
            Write-Verbose "Removing old version of MSBuildTools"
            Start-Process -Wait $BuildToolsExe -ArgumentList ("/uninstall", "/quiet")
        } else {
            Write-Warning "MSBuildTools already exists. Use -Force to overwrite"
            $SkipInstall = $true
        }
    }
    if($SkipInstall -ne $true)
    {
        Write-Verbose "Installing MSBuildTools"    
        Start-Process -Wait $BuildToolsExe -ArgumentList "/quiet"
        
    }
    Remove-Item $BuildToolsExe    

    if(! (Test-Path $MSBuildPath))
    {
        throw "MSBuildTools failed to install"
    }

    if (Test-Path $BuildToolsExe)
    {
        Write-Warning "Failed to cleanup downloaded files at $BuildToolsExe"
    }
    $version = (& $MSBuildPath /version)[3]
    
    if($SkipInstall -ne $true)
    {
        Write-Output "MSBuild version $version installed successfully"
    }
}