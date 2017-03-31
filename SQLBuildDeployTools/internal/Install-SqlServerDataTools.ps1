Function Install-SqlServerDataTools
{
    # https://msdn.microsoft.com/en-gb/mt186501 location to get the admin install for servers without internet access
    [cmdletbinding()]    
    param (
        [switch]$InstallIS,
        [string]$SourceFolder    
    )

    [string[]]$Arguments='/q'
    if($InstallIS) {
        $Arguments.Add('/INSTALLIS=1')
    }

    if($PSBoundParameters.ContainsKey('SourceFolder')) {
        if(Test-Path ($SourceFolder)) {
            # stub
        } else {
            throw
        }
    }
}

