Function Get-MsBuildVersion
{
    [cmdletbinding()]
    param (
        [string]$version = "14.0",
        [string]$MSBuildPath = (Join-Path ${env:ProgramFiles(x86)} "MSBuild\$version\Bin\MSBuild.exe")
    )

    # add validation so that msbuild.exe is there
    
    if (Test-Path $MSBuildPath)
    {
        (& $MSBuildPath /version)[3]
    } 
}