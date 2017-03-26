Function Get-MsDataToolsVersion
{
    [cmdletbinding()]
    param (
        $Path = $env:SBDT_MSDATATOOLSPATH
    )

    if(! [string]::IsNullOrEmpty( $Path ))
    {
        if (Test-Path $Path)
        {
            try {
                $SqlServerDacAssembly = Join-Path $Path "Microsoft.SqlServer.Dac.dll"
                return ([Reflection.AssemblyName]::GetAssemblyName($SqlServerDacAssembly)).Version                
            }
            catch {
                throw
            }
        }
    }    
}