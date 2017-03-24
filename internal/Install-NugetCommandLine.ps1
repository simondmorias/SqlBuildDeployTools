Function Install-NugetCommandLine
{
    [cmdletbinding(DefaultParameterSetName="URL")]
    param (
        [Parameter(Mandatory = $false, ParameterSetName="URL")]
        [string]$Url = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe",

        [Parameter(Mandatory = $false, ParameterSetName="SourcePath")]
        [string]$SourcePath,

        [string]$Path = (Join-Path ${env:ProgramFiles(x86)} "Nuget"),
        [switch]$Force
    )

    if(! (Test-PSUserIsAdmin))
    {
        throw "This command must be run as Administrator"
    }    
    
    $nugetVersion = Get-NugetVersion    
    $nugetExe = Join-Path $Path "nuget.exe"
    
    if([string]::IsNullOrEmpty($nugetVersion) -or $Force)
    {
        if (! (Test-Path $Path))
        {
            New-Item $Path -ItemType Directory -Force > $null
        }

       if ($SourcePath) {
            try
            {                
                if(Test-Path $SourcePath)
                {
                    Write-Output "Copying Nuget command line from $SourcePath to $Path"
                    Copy-Item (Join-Path $SourcePath "nuget.exe") $Path
                }
            }
            catch
            {
                Write-Warning "Failed to copy nuget from $SourcePath. Do you have the correct permissions?"
                throw
            }

        } 
        elseif ($Url) 
        {
            try 
            {
                Write-Output "Installing Nuget command line to $Path"
                Invoke-WebRequest $Url -OutFile $nugetExe -TimeoutSec 20
            }
            catch [System.Net.WebException]
            {
                Write-Warning "Do you have an internet connection? If not try using -SourcePath instead."
                throw            
            }
        }
        Add-ToSystemPath $Path
        Write-Verbose "Path amended to: $env:Path"

        $nugetVersion = Get-NugetVersion
        if([string]::IsNullOrEmpty($nugetVersion))
        {
            throw "Failed to obtain nuget version. Is Nuget in your path?"
        }
        Write-Output "Installed nuget version $nugetVersion in $Path"

    } else {
        Write-Warning "Nuget $nugetVersion already installed. Skipping."
    }       
    [System.Environment]::SetEnvironmentVariable("SBDT_NUGETPATH", $Path)
}