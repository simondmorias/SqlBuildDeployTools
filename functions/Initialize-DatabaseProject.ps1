Function Initialize-DatabaseProject
{
	param ( 
		[string] $DatabaseSolutionFilePath
		,[string] $targetVersion=14
		,[string] $SQLDBExtensionsRefPath="D:\Nuget\Microsoft.Data.Tools.Msbuild\lib\net40"
		,[string] $SSDTPath="D:\Nuget\Microsoft.Data.Tools.Msbuild\lib\net40"
		,[string] $BuildConfiguration="Debug"
		,[string] $MSBuildPath="C:\Windows\Microsoft.NET\Framework64\v4.0.30319"
		,[switch] $Verbose
		)

	if($Verbose) { $VerbosePreference = "Continue" }


	Write-Verbose "MSBuild Path is $MSBuildPath"
	if (-not (Test-Path $MSBuildPath)){
		#Oh dear 
		Throw "It appears that MSBuild 2015 is not installed on this box. Do not attempt to use MicrosoftDataToolsMSBuild as MSBuild 2015 is a pre-requisite."
	}

	$msbuild = "$MSBuildPath\msbuild.exe"

	$arg1 = "/p:tv=$targetVersion"
	$arg2 = "/p:SSDTPath=$SSDTPath"
	$arg3 = "/p:SQLDBExtensionsRefPath=$SQLDBExtensionsRefPath"
	$arg4 = "/p:Configuration=$BuildConfiguration"

	Write-Verbose "First Arguement passed to MSBuild is: $arg1"
	Write-Verbose "Second Arguement passed to MSBuild is: $arg2"
	Write-Verbose "Third Arguement passed to MSBuild is: $arg3"
	Write-Verbose "Fourth Arguement passed to MSBuild is: $arg4"

	Write-Verbose "$msbuild $DatabaseSolutionFilePath $arg1 $arg2 $arg3 $arg4"
	& $msbuild $DatabaseSolutionFilePath $arg1 $arg2 $arg3 $arg4

}