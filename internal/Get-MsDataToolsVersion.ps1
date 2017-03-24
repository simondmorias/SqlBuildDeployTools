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
                ([Reflection.AssemblyName]::GetAssemblyName($SqlServerDacAssembly)).Version                
            }
            catch {
                throw
            }
        }
    }    
}