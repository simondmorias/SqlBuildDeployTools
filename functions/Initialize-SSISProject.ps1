Function Initialize-SSISProject {
<#
.SYNOPSIS 
Initialize-SSISProject builds a Sql Server Integration Services project to produce a ispac.

.DESCRIPTION
Builds a ispac using SSDT. Deploy it with Publish-SSISProject

.PARAMETER SSISProjectPath
The path to the SSIS project file. This can be the folder or the .dtproj file path.

.PARAMETER SolutionPath
The path to the solution that this SSIS project belongs to. Optional.

.PARAMETER SqlServerDataToolsPath
If Sql Server Data Tools has been installed in a different location to the default, specify it here.

.PARAMETER BuildConfiguration
The configuration setting to build. Default is Development.

.PARAMETER Verbose
Shows details of the build, if omitted minimal information is output.

.NOTES
Author: Mark Allison

Requires: 
	SQL Server Data Tools. This module will not auto-install it.
    Admin rights.

.EXAMPLE   
Initialize-SSISProject -SSISProjectPath C:\Projects\MySSISProject

Creates a ispac from the project found in directory C:\Projects\MySSISProject
#>
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
    Write-Verbose "SqlServerDataTools path: $SqlServerDataToolsPath"

    if (-not $PSBoundParameters.ContainsKey('SolutionPath')) {
        Write-Verbose "Solution path not supplied. Searching..."
        $SolutionPath = (Get-ChildItem "$(Split-Path $SSISProjectPath)\..\" *.sln).FullName 
        if ([string]::IsNullOrEmpty($SolutionPath)) {
            throw "Solution path could not be found."
        }
    }
    # get absolute project path
    $SSISProjectPath = (Get-ChildItem "$(Split-Path $SSISProjectPath)" *.dtproj).FullName

    $dateStamp = Get-Date -Format yyyyMMddTHHmmss                
    $logFile = '{0}-Log-{1}.xml' -f $SSISProjectPath, $dateStamp
    $args = @(
        $SolutionPath
        "/rebuild $BuildConfiguration"
        "/project $SSISProjectPath"
        "/log $logFile"
    )  
    Write-Verbose "Arguments passed to devenv: $args"
    Write-Output "Building SSIS Project with $SqlServerDataToolsPath\devenv.com: $SSISProjectPath"

    Start-Process "$SqlServerDataToolsPath\devenv.com" -ArgumentList $args -Wait -NoNewWindow
    $ElapsedTime = (New-TimeSpan –Start $StartTime –End (Get-Date))
    $CompletionMessage = "Success. Time elapsed: {0:g}" -f $ElapsedTime
    Write-Output $CompletionMessage	
}
