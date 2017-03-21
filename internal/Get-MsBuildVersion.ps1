Function Get-MsBuildVersion
{
    [cmdletbinding()]
    param (
        [string]$version = "14.0",
        [string]$MSBuildPath = (Join-Path ${env:ProgramFiles(x86)} "MSBuild\$version\Bin\MSBuild.exe")
    )

    $MSBuildExe = Join-Path $MSBuildPath MSBuild.exe
    if (Test-Path $MSBuildExe)
    {
        (& $MSBuildExe /version)[3]
    } else {
        throw "MSBuild does not exist in path $MSBuildExe"
    }

}