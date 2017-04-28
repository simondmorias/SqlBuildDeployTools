Function Get-SqlServerDataToolsVersion {
    [cmdletbinding()]
    param (
        $Path = $env:SBDT_SQLSERVERDATATOOLSPATH
    )
    Write-Verbose "Getting SSDT Version"
    if ([string]::IsNullOrEmpty($Path)) {
        # default path to search for if env variable not populated - SSDT 14
        $Path = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\Common7\IDE"
    }
    if (Test-Path $Path) {
        [System.Environment]::SetEnvironmentVariable("SBDT_SQLSERVERDATATOOLSPATH", $Path) 
        try {
            Write-Verbose "Getting file version from file $Path"
            $SqlServerDacAssembly = (Join-Path $Path "Microsoft.SqlServer.Dac.dll")
            return (Get-Item (Join-Path $Path "devenv.exe")).VersionInfo
        }
        catch {
            throw "Could not find Sql Server Data Tools. Ensure SSDT 14 or later is installed."
        }
    }
      
}
