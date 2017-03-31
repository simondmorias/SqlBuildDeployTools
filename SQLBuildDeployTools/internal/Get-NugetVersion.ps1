Function Get-NugetVersion
{
    $ErrorActionPreference = "SilentlyContinue"
    try {
        (& nuget.exe)[0].Split(':').Trim()[1]
    }
    catch {
        throw
    }
    finally {
        [System.Environment]::SetEnvironmentVariable("SBDT_NUGETPATH", (Split-Path (Get-Command nuget.exe).Source))
    }        
}