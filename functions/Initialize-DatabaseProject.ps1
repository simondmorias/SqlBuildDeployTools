Function Initialize-DatabaseProject 
{
	# aka Build-DatabaseProject but we're being good and sticking with the approved verbs
	[cmdletbinding()]
	param (
		[parameter(Mandatory=$true)]
		# [ValidatePattern('.+\.sqlproj|.+\.sln')] 
		[string] $DatabaseProjectPath,

		[string] $targetVersion=14,
		[string] $SqlServerDataToolsPath,		
		[string] $MSBuildPath,
		[string] $BuildConfiguration="Debug"
		)
	# populate environment variables
	# $NugetVersion = Get-NugetVersion
	$MsBuildVersion = Get-MsBuildVersion
	# $MsDataToolsVersion = Get-MsDataToolsVersion
	$SqlServerDataToolsVersion = (Get-SqlServerDataToolsVersion).ProductVersion

	Write-Verbose "`nNuget version: $NugetVersion`nMsBuild version: $MsBuildVersion`nMsDataTools version: $SqlServerDataToolsVersion"

	if([string]::IsNullOrEmpty($SqlServerDataToolsPath))
	{
		$SqlServerDataToolsPath = $env:SBDT_SQLSERVERDATATOOLSPATH
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

	if(-not (Test-Path $SqlServerDataToolsPath))
	{
		throw "Sql Server Data Tools not found. Install Sql Server Data Tools and try again."
	}

	# if the directory was specified, find the name of the project file
    if($DatabaseProjectPath.EndsWith('.sqlproj')) {
        $DatabaseProjectFile = $DatabaseProjectPath      
    }
    elseif (Test-Path $DatabaseProjectPath -pathType container) {
        if((Get-ChildItem $DatabaseProjectPath\*.sqlproj).Count -eq 1) {
            $DatabaseProjectFile = Join-Path $DatabaseProjectPath (Get-ChildItem $DatabaseProjectPath *.sqlproj).Name
        }
        else {
            throw "Can't find project file"
        }
    }
	$msbuild = Join-Path $MSBuildPath "msbuild.exe"

	$arg1 = "/p:tv=$targetVersion"
	$arg2 = "/p:SSDTPath=$MicrosoftDataToolsPath"
	$arg3 = "/p:SQLDBExtensionsRefPath=$MicrosoftDataToolsPath"
	$arg4 = "/p:Configuration=$BuildConfiguration"

	Write-Verbose "First Arguement passed to MSBuild is: $arg1"
	Write-Verbose "Second Arguement passed to MSBuild is: $arg2"
	Write-Verbose "Third Arguement passed to MSBuild is: $arg3"
	Write-Verbose "Fourth Arguement passed to MSBuild is: $arg4"

	Write-Verbose "$msbuild $DatabaseSolutionFilePath $arg1 $arg2 $arg3 $arg4"
	& $msbuild $DatabaseProjectFile $arg1 $arg2 $arg3 $arg4

}