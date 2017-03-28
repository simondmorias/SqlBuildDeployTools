Function Initialize-SSISProject 
{
	# aka Build-SSISProject but we're being good and sticking with the approved verbs
	[cmdletbinding()]
	param (
		[parameter(Mandatory=$true)][ValidatePattern(
			'.+\.dtproj'
		)] 
		[string] $SSISProjectPath
    )

	$NugetVersion = Get-NugetVersion
	$MsBuildVersion = Get-MsBuildVersion
	$MsDataToolsVersion = Get-MsDataToolsVersion

	Write-Verbose "`nNuget version: $NugetVersion`nMsBuild version: $MsBuildVersion`nMsDataTools version: $MsDataToolsVersion"

	if ([string]::IsNullOrEmpty($MsBuildVersion)) {
		# MsBuild is not found, let's try and install from the internet
		Write-Warning "MsBuild not found, attempting installation from the internet"
		Install-MsBuild
		$MsBuildVersion = Get-MsBuildVersion
		if ([string]::IsNullOrEmpty($MsBuildVersion))
		{
			throw "MsBuild was not found and the attempt to install from the internet also failed."
		}		
	}

	Write-Verbose "Installing SQL Feature Pack Pre-requisites if required"
	
    $MsBuild = Join-Path $env:SBDT_MSBUILDPATH "MsBuild.exe"	
    $workingdir = Split-Path $script:MyInvocation.MyCommand.Path -Parent
    
    Write-Verbose "Adding Type $workingdir\bin\Microsoft.SqlServer.IntegrationServices.Build.dll"
    Add-Type -Path "$workingdir\bin\Microsoft.SqlServer.IntegrationServices.Build.dll"
	write-verbose "$MsBuild"
    & $MsBuild "$SSISProjectPath /t:SSISBuild"
}