Function Install-NugetCommandLine
{
    [cmdletbinding()]
    param (
        $Url = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe",
        $Path = "${env:ProgramFiles(x86)}\Nuget"
    )

    if(! (Test-PSUserIsAdmin))
    {
        throw "This command must be run as Administrator"
    }    
    
    $SavedErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    $nugetVersion = (& nuget.exe)[0].Split(':').Trim()[1]
    $ErrorActionPreference = $SavedErrorActionPreference
    $nugetExe = "$Path\nuget.exe"
    
    if([string]::IsNullOrEmpty($nugetVersion))
    {
        if (! (Test-Path $Path))
        {
            New-Item $Path -ItemType Directory -Force
        }
        Write-Verbose "Downloading Nuget command line to $Path"
        Invoke-WebRequest $Url -OutFile $nugetExe




        Write-Error "Don't forget to add to PATH!!"



        $nugetVersion = (& nuget.exe)[0].Split(':').Trim()[1]
        Write-Output "Installed nuget version $nugetVersion in $Path"


    } else {
        Write-Warning "Nuget already installed. Skipping."
    }       
}