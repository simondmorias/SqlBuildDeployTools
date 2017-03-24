Function Initialize-Solution 
{
	# aka Build-DatabaseProject but we're being good and sticking with the approved verbs
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
        Initialize-DatabaseProject $DatabaseProjectPath $targetVersion $MicrosoftDataToolsPath $MSBuildPath $BuildConfiguration

}