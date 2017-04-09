Function Publish-SSISProject {
<#
.SYNOPSIS 
Deploys a Sql Server Integration Services project to a SSIS Server

.DESCRIPTION
Deploys

.PARAMETER SSISProjectPath
The path to the SSIS project file. This can be the folder or the .dtproj file path.

.PARAMETER SSISInstanceName
The name of the SQL Server instance to deploy the project to

.PARAMETER SSISFolderName
The SSIS Folder to deploy to on the SSIS Instance

.PARAMETER BuildConfiguration
The configuration setting to build. Default is Development.

.PARAMETER SSISCatalogName
The name of the SSIS Catalog. Usually SSISDB

.PARAMETER Verbose
Shows details of the build, if omitted minimal information is output.

.NOTES
Author: Mark Allison

Requires: 
	SQL Server Data Tools. This module will not auto-install it.
    Admin rights.

.EXAMPLE   
Publish-SSISProject -SSISProjectPath C:\Projects\MySSISProject\MySSISProject.dtproj -SSISInstanceName MYINSTANCE -SSISFolderName TestFolder -Verbose

Deploys an ispac to instance MYINSTANCE in folder TestFolder from the build artifact found in directory C:\Projects\MySSISProject\bin\Development
#>
    [cmdletbinding()]
    param (
		[parameter(Mandatory=$True,Position=1)][ValidatePattern('.+\.dtproj')] [string] $SSISProjectPath,
		[Parameter(Mandatory=$True,Position=2)] [String] $SSISInstanceName,
		[Parameter(Mandatory=$True,Position=3)] [String] $SSISFolderName,		
		[Parameter(Mandatory=$False,Position=4)] [string] $BuildConfiguration = 'Development',
		[Parameter(Mandatory=$False,Position=5)] [String] $SSISCatalogName = 'SSISDB'
    )

	$NugetVersion = Get-NugetVersion
	$MsBuildVersion = Get-MsBuildVersion
	$MsDataToolsVersion = Get-MsDataToolsVersion
	$SqlServerDataToolsVersion = (Get-SqlServerDataToolsVersion).ProductVersion
	$DotNetFrameworkVersion = Get-DotNetVersion

	Write-Verbose "`nNuget version: $NugetVersion`nMsBuild version: $MsBuildVersion`nSSDT version: $SqlServerDataToolsVersion`nMSDataTools Version: $MsDataToolsVersion`nDotNetVersion: $DotNetFrameworkVersion"
	
	# get absolute project path
	$SSISProjectPath = (Get-ChildItem "$(Split-Path $SSISProjectPath)" *.dtproj).FullName
	$IspacPackagePath = (Get-ChildItem (Join-Path (Split-Path $SSISProjectPath) "bin\$BuildConfiguration")).FullName

	Write-Verbose "Loading assembly Microsoft.SqlServer.Management.IntegrationServices"
	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Management.IntegrationServices") > $null

	$sqlConnectionString = "Data Source=$SSISInstanceName;Initial Catalog=master;Integrated Security=SSPI"
	$sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString
	$ssisServer = New-Object Microsoft.SqlServer.Management.IntegrationServices.IntegrationServices $sqlConnection
	$SSISProjectName = [System.IO.Path]::GetFileNameWithoutExtension($SSISProjectPath)
	
	#Check if catalog is already present
	if(!$ssisServer.Catalogs[$SSISCatalogName])	{
		throw "SSIS Catalog $SSISCatalogName does not exist on $SSISInstanceName. Create it and try again."
	}

	$ssisCatalog = $ssisServer.Catalogs[$SSISCatalogName]

	#Check if Folder is already present, if not create one
	if(!$ssisCatalog.Folders.Item($SSISFolderName))
	{
		(New-Object Microsoft.SqlServer.Management.IntegrationServices.CatalogFolder($ssisCatalog,$SSISFolderName,$null)).Create()
	}

	$ssisFolder = $ssisCatalog.Folders.Item($SSISFolderName)

	if(!$ssisFolder.Projects.Item($SSISProjectName))
	{
		$ssisFolder.DeployProject($SSISProjectName,[System.IO.File]::ReadAllBytes($IspacPackagePath))
	}

	#Access deployed project
	$ssisProject = $ssisFolder.Projects.Item($SSISProjectName)

	$ssisProject.Alter()
}