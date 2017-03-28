Function Get-SQLFeaturePackItemVersion
{
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)][ValidateSet(
            'SharedManagementObjects.msi',
            'SQLSysClrTypes.msi')]
        [string]$FeaturePackFileName
    )

    $SQLFeaturePackPaths = @{
        "SharedManagementObjects.msi" = "C:\Program Files\Microsoft SQL Server\100\SDK\Assemblies\Microsoft.SqlServer.Smo.dll";
        "SQLSysClrTypes.msi" = "C:\Program Files (x86)\Microsoft SQL Server\100\SDK\Assemblies\Microsoft.SqlServer.Types.dll"
    }

    return ([Reflection.AssemblyName]::GetAssemblyName($SQLFeaturePackPaths.Get_Item($FeaturePackFileName))).Version                
}