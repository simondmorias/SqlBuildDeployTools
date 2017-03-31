Function Initialize-SSISProject {
    # aka Build-SSISProject but we're being good and sticking with the approved verbs
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $true)][ValidatePattern(
            '.+\.dtproj'
        )]		 
        [string] $SSISProjectPath,
		
        [string] $SolutionPath,
        [string] $SqlServerDataToolsPath,
        [string] $BuildConfiguration = "Development"
    )
    $StartTime = Get-Date
    if (-not $PSBoundParameters.ContainsKey('SqlServerDataToolsPath')) {
        $SqlServerDataToolsVersion = (Get-SqlServerDataToolsVersion).ProductVersion
        $SqlServerDataToolsPath = $env:SBDT_SQLSERVERDATATOOLSPATH
    }
    else {
        $SqlServerDataToolsVersion = (Get-SqlServerDataToolsVersion $SqlServerDataToolsPath).ProductVersion
    }
		
    if ([string]::IsNullOrEmpty($SqlServerDataToolsVersion)) {
        throw "Sql Server Data Tools not found. Install Sql Server Data Tools and try again."		
    }	
    Write-Verbose "SqlServerDataTools version: $SqlServerDataToolsVersion"

    if (-not $PSBoundParameters.ContainsKey('SolutionPath')) {
        Write-Verbose "Solution path not supplied. Searching..."
        $SolutionPath = (Get-ChildItem "$(Split-Path $SSISProjectPath)}\..\" *.sln).FullName 
        if ([string]::IsNullOrEmpty($SolutionPath)) {
            throw "Solution path could not be found."
        }
    }

    $args = @(
        $SolutionPath
        "/rebuild $BuildConfiguration"
        "/project $SSISProjectPath"
    )  
    Write-Output "Building SSIS Project: $SSISProjectPath"
    Start-Process "$SqlServerDataToolsPath\devenv.com" -ArgumentList $args -Wait -NoNewWindow
    $ElapsedTime = (New-TimeSpan –Start $StartTime –End (Get-Date))
    $CompletionMessage = "Success. Time elapsed: {0:g}" -f $ElapsedTime
    Write-Output $CompletionMessage	
}