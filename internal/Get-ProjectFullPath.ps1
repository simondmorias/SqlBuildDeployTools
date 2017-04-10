Function Get-ProjectFullPath
{
    [cmdletbinding()]
    param(
        $ProjectPath,
        $ProjectFileExtension
    )
    if (-not ($ProjectPath.EndsWith($ProjectFileExtension))) {
        if (Test-Path $ProjectPath -PathType Container) { # the path is a directory
            if((Get-ChildItem $ProjectPath\*$ProjectFileExtension).Count -eq 1) {
                return Join-Path $ProjectPath (Get-ChildItem $ProjectPath *$ProjectFileExtension).Name
            }
            else {
                throw "Can't find project file"
            }
        }
    } else {
        return $ProjectPath
    }
}