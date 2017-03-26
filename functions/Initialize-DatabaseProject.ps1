Function Initialize-DatabaseProject 
{
	# aka Build-DatabaseProject but we're being good and sticking with the approved verbs
	[cmdletbinding()]
	param (
		[parameter(Mandatory=$true)][ValidatePattern(
			'.+\.sqlproj|.+\.sln'
		)] 
		[string] $DatabaseProjectPath,

		[string] $targetVersion=14,
		[string] $MicrosoftDataToolsPath,		
		[string] $MSBuildPath,
		[string] $BuildConfiguration="Debug"
		)

	# populate environment variables
	$NugetVersion = Get-NugetVersion
	$MsBuildVersion = Get-MsBuildVersion
	$MsDataToolsVersion = Get-MsDataToolsVersion

	Write-Verbose "`nNuget version: $NugetVersion`nMsBuild version: $MsBuildVersion`nMsDataTools version: $MsDataToolsVersion"

	if([string]::IsNullOrEmpty($MicrosoftDataToolsPath))
	{
		$MicrosoftDataToolsPath = $env:SBDT_MSDATATOOLSPATH
	}
	if([string]::IsNullOrEmpty($MSBuildPath))
	{
		$MSBuildPath = $env:SBDT_MSBUILDPATH
	}
	
	if (-not (Test-Path $MSBuildPath)){
		# MsBuild is not found, let's try and install from the internet
		Write-Warning "MsBuild not found, attempting installation from the internet"
		Install-MsBuild
		if ([string]::IsNullOrEmpty($env:SBDT_MSBUILDPATH))
		{
			throw "MsBuild was not found and the attempt to install from the internet also failed."
		}
	}	

	if(-not (Test-Path $MicrosoftDataToolsPath))
	{
		Write-Warning "Microsoft Data Tools not found. Attempting nuget install"
		Install-MsDataTools
		if ([string]::IsNullOrEmpty($env:SBDT_MSDATATOOLSPATH))
		{
			throw "Ms Data Tools was not found and the attempt to install the Nuget Package also failed."
		}		
	}

	$msbuild = "$MSBuildPath\msbuild.exe"

	$arg1 = "/p:tv=$targetVersion"
	$arg2 = "/p:SSDTPath=$MicrosoftDataToolsPath"
	$arg3 = "/p:SQLDBExtensionsRefPath=$MicrosoftDataToolsPath"
	$arg4 = "/p:Configuration=$BuildConfiguration"

	Write-Verbose "First Arguement passed to MSBuild is: $arg1"
	Write-Verbose "Second Arguement passed to MSBuild is: $arg2"
	Write-Verbose "Third Arguement passed to MSBuild is: $arg3"
	Write-Verbose "Fourth Arguement passed to MSBuild is: $arg4"

	Write-Verbose "$msbuild $DatabaseSolutionFilePath $arg1 $arg2 $arg3 $arg4"
	& $msbuild $DatabaseProjectPath $arg1 $arg2 $arg3 $arg4
}