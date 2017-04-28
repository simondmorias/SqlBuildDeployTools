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
        $arguments = "install $nugetPackage", "-ExcludeVersion", "-OutputDirectory `"$DataToolsPath`""
        if($PSBoundParameters.ContainsKey('$NugetPackageVersion')) {
            $arguments.Add("-Version $NugetPackageVersion")
        }
        Write-Verbose "Running command: nuget.exe install $nugetPackage $arguments"
        Start-Process nuget.exe -ArgumentList $arguments -Wait -NoNewWindow
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