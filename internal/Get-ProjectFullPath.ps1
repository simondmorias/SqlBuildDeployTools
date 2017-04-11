Function Get-ProjectFullPath
{
    [cmdletbinding()]
    param(
        $ProjectPath,
        $ProjectFileExtension
    )
    if (-not ($ProjectPath.EndsWith($ProjectFileExtension))) {
        Write-Verbose "$ProjectPath does not end with $ProjectFileExtension"
        if (Test-Path $ProjectPath -PathType Container) { # the path is a directory
            Write-Verbose "$ProjectPath is a directory (not a file)"
            if((Get-ChildItem $ProjectPath\*$ProjectFileExtension).Count -eq 1) {
                Write-Verbose "There is 1 file with an extension of $ProjectFileExtension in $ProjectPath"
                return (Get-ChildItem $ProjectPath\*$ProjectFileExtension).FullName
            }
            else {
                throw "Can't find project file"
            }
        }
    } else {
        
        if (Test-Path $ProjectPath -PathType leaf) {
            Write-Verbose "$ProjectPath is a file"
            return (Get-ChildItem $ProjectPath).FullName
        } else {
            throw "Unknown error discovering path to project file."
        }        
    }
}