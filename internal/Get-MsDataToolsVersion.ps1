Function Get-MsDataToolsVersion
{
    [cmdletbinding()]
    param (
        $Path = $env:SBDT_MSDATATOOLSPATH
    )

    if([string]::IsNullOrEmpty($Path)) {
        $NugetVersion = Get-NugetVersion
        $Path = Join-Path ${env:SBDT_NUGETPATH} "Packages\Microsoft.Data.Tools.Msbuild\lib\net40"
    }

    if (Test-Path $Path)
    {
        [System.Environment]::SetEnvironmentVariable("SBDT_MSDATATOOLSPATH", $Path) 
        try {
            Write-Verbose "Getting file version from file $Path"
            $SqlServerDacAssembly = (Join-Path $Path "Microsoft.SqlServer.Dac.dll")
            return ([Reflection.AssemblyName]::GetAssemblyName($SqlServerDacAssembly)).Version            
        }
        catch {
            throw
        }
    }
      
}