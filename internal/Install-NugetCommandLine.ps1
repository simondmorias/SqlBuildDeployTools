Function Install-NugetCommandLine
{
    [cmdletbinding(DefaultParameterSetName="URL")]
    param (
        [Parameter(Mandatory = $false, ParameterSetName="URL")]
        [string]$Url = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe",

        [Parameter(Mandatory = $false, ParameterSetName="SourcePath")]
        [string]$SourcePath,

        [string]$Path = (Join-Path "$env:ProgramFiles(x86)" "Nuget"),
        [switch]$Force
    )

    if(! (Test-PSUserIsAdmin))
    {
        throw "This command must be run as Administrator"
    }    
    
    $nugetVersion = Get-NugetVersion    
    $nugetExe = Join-Path $Path "nuget.exe"
    
    if([string]::IsNullOrEmpty($nugetVersion) -or $force)
    {
        if (! (Test-Path $Path))
        {
            New-Item $Path -ItemType Directory -Force > $null
        }
        try 
        {
            Write-Verbose "Downloading Nuget command line to $Path"
            Invoke-WebRequest $Url -OutFile $nugetExe -TimeoutSec 20
        }
        catch [System.Net.WebException]
        {
            Write-Warning "Do you have internet connection? If not try using -SourcePath instead."
            throw            
        }

        # remove old nuget from the system path
        $env:path = ($env:path.Split(';') | Where-Object { $_ -notmatch 'nuget' }) -join ';'
        
        # add the new path
        $env:Path = "$env:Path;$Path;"

        Write-Verbose "Path amended to: $env:Path"

        $nugetVersion = Get-NugetVersion
        Write-Output "Installed nuget version $nugetVersion in $Path"

    } else {
        Write-Warning "Nuget already installed. Skipping."
    }       
}