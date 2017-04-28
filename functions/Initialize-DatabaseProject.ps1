Function Initialize-DatabaseProject 
{
<#
.SYNOPSIS 
Builds a Sql Server Data Tools project to produce a .dacpac file.

.DESCRIPTION
Builds a dapac using MSBuild from an SSDT project. By default the build will be attempted using the Microsoft.Data.Tools.Msbuild nuget package. If this fails or does not exist, an installation is attempted.

.PARAMETER DatabaseProjectPath
The path to the project file. This can be the folder or the .sqlproj file path.

.PARAMETER TargetVersion
Target version to build. Default is 14.

.PARAMETER MsDataToolsPath
If you want to specify the path to the Microsoft.Data.Tools package, specify it here. Not required.

.PARAMETER MSBuildPath
The path to MSBuild. If this is different to the default specify it here.

.PARAMETER BuildConfiguration
The configuration setting to build. Default is Debug.

.PARAMETER Verbose
Shows details of the build, if omitted minimal information is output.

.NOTES
Author: Mark Allison

Requires: 
	Microsoft.Data.Tools.Msbuild nuget package installed. This module will attempt to auto-install it if missing.
	MSBuild installed. This module will attempt to auto-install it if missing.
	Nuget installed. This module will attempt to auto-install it if missing.
    Admin rights.

.EXAMPLE   
Initialize-DatabaseProject -DatabaseProjectPath C:\Projects\MyDatabaseProject

Creates a dacpac from the project found in directory C:\Projects\MyDatabaseProject
#>
	[cmdletbinding()]
	param (
		[parameter(Mandatory=$true)][string] $DatabaseProjectPath,
		# [ValidatePattern('.+\.sqlproj|.+\.sln')] 
		
		[string] $TargetVersion=14,
		[string] $MsDataToolsPath,		
		[string] $MSBuildPath,
		[string] $BuildConfiguration="Debug"
		)
	# populate environment variables & get versions
	$NugetVersion = Get-NugetVersion
	$MsBuildVersion = Get-MsBuildVersion
	$MsDataToolsVersion = Get-MsDataToolsVersion
	$SqlServerDataToolsVersion = (Get-SqlServerDataToolsVersion).ProductVersion
	$DotNetFrameworkVersion = Get-DotNetVersion

	Write-Verbose "`nNuget version: $NugetVersion`nMsBuild version: $MsBuildVersion`nSSDT version: $SqlServerDataToolsVersion`nMSDataTools Version: $MsDataToolsVersion`nDotNetVersion: $DotNetFrameworkVersion"

	if(-not ($PSBoundParameters.ContainsKey('MSBuildPath'))) {
		$MSBuildPath = $env:SBDT_MSBUILDPATH
	}

	if ([string]::IsNullOrEmpty($MSBuildPath) -or (-not(Test-Path $MSBuildPath))) {
		Write-Warning "MSBuild not found, attempting installation"
		Install-MSBuild
		if([string]::IsNullOrEmpty($env:SBDT_MSBUILDPATH) -or (-not (Test-Path ($env:SBDT_MSBUILDPATH)))) {
			throw "MsBuild was not found."
		}
		$MSBuildPath = $env:SBDT_MSBUILDPATH
	}	

	if(-not ($PSBoundParameters.ContainsKey('MsDataToolsPath'))) {
		$MsDataToolsPath = $env:SBDT_MSDATATOOLSPATH
	}
	if([string]::IsNullOrEmpty($MsDataToolsPath) -or (-not (Test-Path $MsDataToolsPath))) {
		Write-Warning "Ms Data Tools not found, attempting installation."		
		Install-MsDataTools
		if([string]::IsNullOrEmpty($env:SBDT_MSDATATOOLSPATH)) {
			throw "Microsoft Data Tools package not found. Attempt to install also failed."
		}
		$MsDataToolsPath = $env:SBDT_MSDATATOOLSPATH
	}

	# if the directory was specified, find the name of the project file
	$DatabaseProjectFile = Get-ProjectFullPath $DatabaseProjectPath ".sqlproj"
	$msbuild = Join-Path $MSBuildPath "msbuild.exe"

    $args = @(
        "/p:tv=$targetVersion"
        "/p:SSDTPath=$MsDataToolsPath"
        "/p:SQLDBExtensionsRefPath=$MsDataToolsPath"
		"/p:Configuration=$BuildConfiguration"
    )  
	Write-Verbose "Arguments passed to MSBuild:`n$args"

	Write-Verbose "$msbuild $DatabaseSolutionFilePath $args"
	& $msbuild $DatabaseProjectFile $args
}