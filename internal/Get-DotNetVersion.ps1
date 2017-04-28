Function Get-DotNetVersion
{
    Write-Verbose "Getting DotNet version"
    # Reference: https://msdn.microsoft.com/en-us/library/hh925568(v=vs.110).aspx
    $DotNetFrameWorkVersions = @{
        394806 = "4.6.2";
        394802 = "4.6.2";
        394271 = "4.6.1";
        394254 = "4.6.1";
        393297 = "4.6";
        393295 = "4.6";
        379893 = "4.5.2";
        378758 = "4.5.1";
        378675 = "4.5.1";
        378389 = "4.5";
    }

    $DotNetFrameWorkRelease = (Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" ).Release
    return $DotNetFrameWorkVersions.Get_Item($DotNetFrameWorkRelease)
}