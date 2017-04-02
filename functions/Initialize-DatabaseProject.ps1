Function Initialize-DatabaseProject 
{
<#
.SYNOPSIS 
Initialize-DatabaseProject builds a Sql Server project to produce a dacpac.

.DESCRIPTION
Builds a dapac using MSBuild from an SSDT project.

.PARAMETER DatabaseProjectPath
The path to the project file. This can be the folder or the .sqlproj file path.

.PARAMETER DatabaseProjectPath
Target version to build. Default is 14.

.PARAMETER SqlServerDataToolsPath
If Sql Server Data Tools has been installed in a different location to the default, specify it here.

.PARAMETER MSBuildPath
The path to MSBuild. If this is different to the default specify it here.

.PARAMETER BuildConfiguration
The configuration setting to build. Default is Debug.

.PARAMETER Verbose
Shows details of the build, if omitted minimal information is output.

.NOTES
Author: Mark Allison

Requires: 
	SQL Server Data Tools. This module will not auto-install it.
	Nuget (if nuget is not detected, this function will try to install it)
    Admin rights.

.EXAMPLE   
Initialize-DatabaseProject -DatabaseProjectPath C:\Projects\MyDatabaseProject

Creates a dacpac from the project found in directory C:\Projects\MyDatabaseProject
#>
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
	# populate environment variables & get versions
	$NugetVersion = Get-NugetVersion
	$MsBuildVersion = Get-MsBuildVersion
	$SqlServerDataToolsVersion = (Get-SqlServerDataToolsVersion).ProductVersion

	Write-Verbose "`nNuget version: $NugetVersion`nMsBuild version: $MsBuildVersion`nSSDT version: $SqlServerDataToolsVersion"

	if(-not ($PSBoundParameters.ContainsKey('SqlServerDataToolsPath'))) {
		$SqlServerDataToolsPath = $env:SBDT_SQLSERVERDATATOOLSPATH
	}
	if(-not ($PSBoundParameters.ContainsKey('MSBuildPath'))) {
		$MSBuildPath = $env:SBDT_MSBUILDPATH
	}
	
	if (-not (Test-Path $MSBuildPath)) {
		throw "MsBuild was not found."
	}	

	if(-not (Test-Path $SqlServerDataToolsPath)) {
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