Function Install-MSIPackage {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

    Write-Verbose "Testing file hash for $($File)"
    if (Test-FileHash ($File)) {
        Write-Verbose "Unblocking $($File)"
        Unblock-File $File
    }
    else {
        throw "Unexpected file hash for $File. Cannot unblock file for installation."
    }

    $dateStamp = Get-Date -Format yyyyMMddTHHmmss                
    $logFile = '{0}-{1}.log' -f $file.FullName, $dateStamp                
    $MSIArguments = @(
        "/i"
        ('"{0}"' -f $file.FullName)
        "/qn"
        "/norestart"
        "/L*v"
        $logFile
    )  
    Write-Output "Installing $($File)"
    Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow
    Write-Output "Success"
}
