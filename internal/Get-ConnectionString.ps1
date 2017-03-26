Function Get-ConnectionString
{
    [cmdletbinding()]
    param (
        [parameter(Mandatory=$true)]
        [string]$InstanceName,

        [parameter(Mandatory=$true)]
        [string]$DatabaseName,

        [parameter(ParameterSetName="SqlLogin")]
        [string]$SqlLogin,

        [parameter(ParameterSetName="SqlLogin")]
        [string]$Password
    )

    if($PSBoundParameters.ContainsKey($SqlLogin))
    {
        $ConnectionString = "Server=$InstanceName;Database=$DatabaseName;Uid=$SqlLogin;Pwd=$Password;"
    }
    else {
        $ConnectionString = "Server=$InstanceName;Database=$DatabaseName;Trusted_Connection=yes;"
    }
    return $ConnectionString
}