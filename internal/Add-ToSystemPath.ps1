Function Add-ToSystemPath 
{
    param (
        [Parameter(Mandatory = $true)]
<#        [ValidatePattern(
            '^(?:[a-zA-Z]\:+)\\(?:[\w]+\\)*\w([\w.])+$'
        )]#>
        [string]$Item
    )

    $validPath = [System.IO.Path]::GetFullPath($Item)

    if($env:Path.Split(';') -contains $validPath)
    {
        Write-Warning "$validPath Path already exists"
    } else {
        $env:Path = "$env:Path;$validPath;"
    }
}