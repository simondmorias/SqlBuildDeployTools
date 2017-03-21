Function Install-MicrosoftDataTools
{
    [cmdletbinding()]
    param (
        [string]$NugetInstallPath = (Join-Path "$env:ProgramFiles(x86)" "Nuget\Packages")
    )

    $nugetVersion = Get-NugetVersion
    if ([string]::IsNullOrEmpty($nugetVersion))
    {
        Write-Verbose "Nuget not found, attempting installation from the internet."
        Install-NugetCommandLine -Force
    }
    $nugetPackage = "Microsoft.Data.Tools.Msbuild"
    Write-Verbose "Installing nuget package $nugetPackage"
    
    & nuget.exe install $nugetPackage -ExcludeVersion -OutputDirectory $NugetInstallPath
}