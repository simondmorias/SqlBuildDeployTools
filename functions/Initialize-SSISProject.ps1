Function Initialize-SSISProject {
<#
.SYNOPSIS 
Builds a Sql Server Integration Services project to produce a .ispac file.

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

Fails to build on Windows Server 2016 with:
"Microsoft Visual Studio has detected a configuration issue. To correct this, please restart as Administrator. For more information please visit: http://go.microsoft.com/fwlink/?LinkId=558821"" 

.EXAMPLE   
Initialize-SSISProject -SSISProjectPath C:\Projects\MySSISProject

Creates a ispac from the project found in directory C:\Projects\MySSISProject
#>
    [cmdletbinding()]
    param (
        [parameter(Mandatory=$true)][string] $SSISProjectPath,		
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
    # get absolute project path in case a directory was passed
    $SSISProjectPath = 	Get-ProjectFullPath $SSISProjectPath ".dtproj"

    $dateStamp = Get-Date -Format yyyyMMddTHHmmss                
    $logFile = '{0}-Log-{1}.txt' -f $SSISProjectPath, $dateStamp
    $args = @(
        $SolutionPath
        "/build $BuildConfiguration"
        "/project $SSISProjectPath"
        "/out $logFile"
    )
    Write-Verbose "Arguments passed to devenv: $args"
    Write-Output "Building SSIS Project with $SqlServerDataToolsPath\devenv.com: $SSISProjectPath"

    Start-Process -Wait -NoNewWindow "$SqlServerDataToolsPath\devenv.com" -ArgumentList $args    
    $ElapsedTime = (New-TimeSpan –Start $StartTime –End (Get-Date))
    
    # get the content of the log file because devenv doesn't do it when run within a powershell console
    $logFileContent = Get-Content $logFile
    $logFileContent
    # throw an error if the word error appears in the log file 
    foreach ($line in $logFileContent) {
        if($line -match "[E|e]rror") {
            throw "Error in build. $line"
        }
    }
    $CompletionMessage = "Success. Time elapsed: {0:g}" -f $ElapsedTime
    Write-Output $CompletionMessage	
}
