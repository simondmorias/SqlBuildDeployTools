Function Get-MsDataToolsVersion
{
    [cmdletbinding()]
    param (
        $Path = $env:SBDT_MSDATATOOLSPATH
    )
    Write-Verbose "Getting Microsoft.Data.Tools.Msbuild Version"
    if([string]::IsNullOrEmpty($Path)) {
        if([string]::IsNullOrEmpty(${env:SBDT_NUGETPATH})) {
            $NugetVersion = Get-NugetVersion
        }
        if(-not ([string]::IsNullOrEmpty(${env:SBDT_NUGETPATH}))) {
            $Path = Join-Path ${env:SBDT_NUGETPATH} "Packages\Microsoft.Data.Tools.Msbuild\lib\net40"
        }
    }

    # if the path variable is populated and valid
    if (-not ([string]::IsNullOrEmpty($Path)) -and (Test-Path $Path))
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