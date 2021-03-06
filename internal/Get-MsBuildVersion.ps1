Function Get-MsBuildVersion {
    [cmdletbinding()]
    param (
        [string]$version = "14.0",
        [string]$MSBuildPath = (Join-Path ${env:ProgramFiles(x86)} "MSBuild\$version\Bin\MSBuild.exe")
    )
    Write-Verbose "Getting MsBuild Version"
    if ([string]::IsNullOrEmpty($MSBuildPath)) {
        $MSBuildPath = $env:SBDT_MSBUILDPATH
    }
    if (Test-Path ($MSBuildPath)) {
        $MsBuildVersion = (& $MSBuildPath /version)[3]
        [System.Environment]::SetEnvironmentVariable("SBDT_MSBUILDPATH", (Split-Path $MSBuildPath))
        return $MsBuildVersion 
    }
    else {
        Write-Warning "MsBuild not found in $MSBuildPath"
    }
}
