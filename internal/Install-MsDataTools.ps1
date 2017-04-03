Function Install-MsDataTools
{
    [cmdletbinding()]
    param (
        [string]$DataToolsPath,
        [string]$NugetPackageVersion
    )

    $nugetVersion = Get-NugetVersion
    if ([string]::IsNullOrEmpty($nugetVersion))
    {
        Write-Verbose "Nuget not found, attempting installation from the internet."
        Install-NugetCommandLine -Force
    }
    
    $nugetPackage = "Microsoft.Data.Tools.Msbuild"
    if ([string]::IsNullOrEmpty( $DataToolsPath))
    {
        $DataToolsPath = Join-Path ${env:SBDT_NUGETPATH} "Packages"
    }
     
    try
    {
        Write-Output "Installing nuget package $nugetPackage"
        if($PSBoundParameters.ContainsKey('$NugetPackageVersion')) {
            $args = @(
                "-ExcludeVersion"
                "-OutputDirectory $DataToolsPath"
                "-Version $NugetPackageVersion"
            )            
        } else {
            $args = @(
                "-ExcludeVersion"
                "-OutputDirectory $DataToolsPath"
            )
        }
        & nuget.exe install $nugetPackage $args
    }
    catch
    {
        throw
    }
    $FullDataToolsPath = Join-Path $DataToolsPath "Microsoft.Data.Tools.Msbuild\lib\net40"
    [System.Environment]::SetEnvironmentVariable("SBDT_MSDATATOOLSPATH", $FullDataToolsPath)
    
    $version = (Get-MsDataToolsVersion).Major
    Write-Output "Microsoft.Data.Tools.Msbuild version $version installed to $DataToolsPath\Microsoft.Data.Tools.Msbuild"   
}