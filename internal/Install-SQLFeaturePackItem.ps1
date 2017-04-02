# not required now as SSDT takes care of it
Function Install-SQLFeaturePackItem
{
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)][ValidateSet(
            'SharedManagementObjects.msi',
            'SQLSysClrTypes.msi')]
        [string]$FeaturePackFileName,

        [string]$SourcePath,
        [switch]$Force
    )

    if(! (Test-PSUserIsAdmin)) {
        throw "This command must be run as Administrator"
    }
    $SQLFeaturePackURLs = @{
        "SharedManagementObjects.msi" = "https://go.microsoft.com/fwlink/?LinkID=188439&clcid=0x409";
        "SQLSysClrTypes.msi" = "https://go.microsoft.com/fwlink/?LinkID=188392&clcid=0x409"
    }

    $DownloadPath = Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads"    
    $FeaturePackURL = $SQLFeaturePackURLs.Get_Item($FeaturePackFileName)
    $FeaturePackDownloadPath = Join-Path $DownloadPath $FeaturePackFileName
    Write-Debug "FeaturePackDownloadPath $FeaturePackDownloadPath"
    # if the file doesn't exist or we want to force
    if(! (Test-Path $FeaturePackDownloadPath) -or $Force)
    {
        if($SourcePath)
        {
            try {
                if(Test-Path $SourcePath)
                {
                    Write-Verbose "Copying $FeaturePackFileName from $SourcePath to $DownloadPath"
                    Copy-Item (Join-Path $SourcePath $FeaturePackFileName) $DownloadPath
                }
                else {
                    throw "$SourcePath does not exist. Specify a valid location for -SourcePath."
                }
            }
            catch {
                Write-Warning "Failed to copy $FeaturePackFileName from $SourcePath. Do you have the correct permissions?"
                throw
            }
        }
        else {
            try {
                Write-Verbose "Downloading $FeaturePackFileName from $FeaturePackURL to $DownloadPath"
                $wc = New-Object Net.WebClient
                $wc.DownloadFile($FeaturePackURL, $FeaturePackDownloadPath)            
            }
            catch [System.Net.WebException] {
                Write-Warning "Do you have an internet connection?  If not try using -SourcePath instead."
                throw 
            }
        }        
    }
    else {
        Write-Warning "$FeaturePackDownloadPath already exists and -Force not specified. Using existing downloaded file."
    }
    
    Write-Output "Installing feature pack item $FeaturePackDownloadPath"    
    Install-MSIPackage $FeaturePackDownloadPath 
}