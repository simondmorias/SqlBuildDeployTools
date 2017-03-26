Function Install-MsBuild
{
    [cmdletbinding(DefaultParameterSetName="URL")]
    param (
        [Parameter(Mandatory = $false, ParameterSetName="URL")]
        [string]$Url = "https://download.microsoft.com/download/E/E/D/EEDF18A8-4AED-4CE0-BEBE-70A83094FC5A/BuildTools_Full.exe",
        
        [Parameter(Mandatory = $false, ParameterSetName="SourcePath")]
        [string]$SourcePath,

        [string]$version = "14.0",
        [switch]$Force
    )

    if(! (Test-PSUserIsAdmin))
    {
        throw "This command must be run as Administrator"
    }

    $MsBuildVersion = Get-MsBuildVersion    
    $DownloadPath = Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads"    
    $MSBuildToolsInstaller = Join-Path $DownloadPath "BuildTools_Full.exe"
    $MSBuildPath = Join-Path ${env:ProgramFiles(x86)} "MSBuild\$version\Bin" 
    $MSBuildExe = "$MSBuildPath\MsBuild.exe"
    
    # get the installer if it doesn't exist or -Force specified
    if(! (Test-Path $MSBuildToolsInstaller) -or $Force)
    {
        if ($SourcePath) 
        {
            try
            {                
                if(Test-Path $SourcePath)
                {
                    Write-Verbose "Copying MsBuild installer from $SourcePath to $DownloadPath"
                    Copy-Item (Join-Path $SourcePath "BuildTools_Full.exe") $DownloadPath
                }
                else {
                    throw "$SourcePath does not exist. Specify a valid location to obtain MsBuild installer."
                }
            }
            catch
            {
                Write-Warning "Failed to copy MSBuild from $SourcePath. Do you have the correct permissions?"
                throw
            }
        } 
        elseif ($Url)
        {
            try 
            {
                Write-Verbose "Downloading MSBuildTools to $MSBuildToolsInstaller"
                $wc = New-Object Net.WebClient
                $wc.DownloadFile($url, $MSBuildToolsInstaller)
            }
            catch [System.Net.WebException]
            {
                Write-Warning "Do you have an internet connection?  If not try using -SourcePath instead."
                throw            
            }
        }              
    }

    # remove MsBuild if it exists and -Force was specified - NOT WORKING 

<#    if((Test-Path $MSBuildPath) -and $Force)
    {
        Unblock-File $MSBuildToolsInstaller
        Write-Verbose "Removing old version of MSBuildTools"
        Start-Process -Wait $MSBuildToolsInstaller -ArgumentList ("/uninstall", "/quiet")

        if (Test-Path $MSBuildExe)
        {
            throw "Failed to uninstall old version of MsBuild."
        }
    }
#>
    # install MsBuild if it doesn't exist
    if(! (Test-Path $MSBuildPath))
    {
        Write-Output "Installing MSBuildTools"    
        Start-Process -Wait $MSBuildToolsInstaller -ArgumentList "/quiet"
    }
        
    if(! (Test-Path $MSBuildPath))
    {
        throw "MSBuildTools failed to install"
    }

    if (Test-Path $MSBuildToolsInstaller)
    {
        Write-Verbose "Removing installer"
        Remove-Item $MSBuildToolsInstaller
    }

    $version = Get-MsBuildVersion
    Write-Output "MSBuild version $version is installed."

    # save the path in case other functions want to use it
    [System.Environment]::SetEnvironmentVariable("SBDT_MSBUILDPATH", $MSBuildPath)    
}