Function Test-FileHash
{
    [cmdletbinding()]
    param (
        [parameter(Mandatory=$true)]
        $File
    )
    $workingdir = Split-Path $script:MyInvocation.MyCommand.Path -Parent
    $hash = (Get-FileHash $File -Algorithm SHA256).Hash
    $fileName = Split-Path $File -Leaf
    $expectedHash = (Get-Content "$workingdir\config\filehashes.json" | ConvertFrom-Json).$fileName
    if(-not ([string]::IsNullOrEmpty($expectedHash))) {
        return ($expectedHash -eq $hash)
    } else {
        Write-Warning "Unknown hash for $File"
    }    
}