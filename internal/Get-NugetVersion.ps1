Function Get-NugetVersion
{
    $ErrorActionPreference = "SilentlyContinue"
    (& nuget.exe)[0].Split(':').Trim()[1]
}