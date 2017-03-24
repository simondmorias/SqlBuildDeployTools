Function Initialize-SSISProject 
{
	# aka Build-DatabaseProject but we're being good and sticking with the approved verbs
	param (
		[parameter(Mandatory=$true)][ValidatePattern(
			'.+\.dtproj'
		)] 
		[string] $SSISProjectPath
    )


    $MsBuildVersion = Get-MsBuildVersion
	if([string]::IsNullOrEmpty($MSBuildPath))
	{
		$MSBuildPath = $env:SBDT_MSBUILDPATH
	}

	if ([string]::IsNullOrEmpty($MSBuildPath)) {
		# MsBuild is not found, let's try and install from the internet
		Write-Warning "MsBuild not found, attempting installation from the internet"
		Install-MsBuild
		$MsBuildVersion = Get-MsBuildVersion
		if ([string]::IsNullOrEmpty($MsBuildVersion))
		{
			throw "MsBuild was not found and the attempt to install from the internet also failed."
		}
		$MSBuildPath = $env:SBDT_MSBUILDPATH
	}
	
    $MsBuild = Join-Path $MSBuildPath "MsBuild.exe"	
    $workingdir = Split-Path $script:MyInvocation.MyCommand.Path -Parent
    
    Write-Verbose "Adding Type $workingdir\bin\Microsoft.SqlServer.IntegrationServices.Build.dll"
    Add-Type -Path "$workingdir\bin\Microsoft.SqlServer.IntegrationServices.Build.dll"
	write-verbose "$MsBuild"
    & $MsBuild "$SSISProjectPath /t:SSISBuild"
    }