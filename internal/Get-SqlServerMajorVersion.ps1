Function Get-SqlServerMajorVersion
{
    [cmdletbinding()]
    param(
        [string]$sqlServerVersion
    )
    switch($sqlserverVersion)
    {
        "2008-R2"
        {
            $majorVersion = 100
        }
        "2012"
        {
            $majorVersion = 110
        }
        "2014"
        {
            $majorVersion = 120
        }
        "2016"
        {
            $majorVersion = 130
        }
    }
    return $majorVersion
}