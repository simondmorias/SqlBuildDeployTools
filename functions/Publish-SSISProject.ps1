Function Publish-SSISProject {
<#
.SYNOPSIS 
Deploys a Sql Server Integration Services project to a SSIS Server

.DESCRIPTION
Deploys

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
Publish-SSISProject -SSISProjectPath C:\Projects\MySSISProject

Creates a ispac from the project found in directory C:\Projects\MySSISProject
#>
    [cmdletbinding()]
    param (
		[Parameter(Mandatory=$True,Position=1)] [String] $SSISInstanceName,
		[Parameter(Mandatory=$True,Position=2)] [String] $SSISFolderName,
		[Parameter(Mandatory=$True,Position=3)] [String] $SSISProjectName, # do we need this?
		[Parameter(Mandatory=$True,Position=4)] [String] $IspacPackagePath,
		[Parameter(Mandatory=$False,Position=5)] [String] $SSISCatalogName = "SSISDB",
		[Parameter(Mandatory=$False,Position=6)] [Switch] $Force = $false
    )

	$NugetVersion = Get-NugetVersion
	$MsBuildVersion = Get-MsBuildVersion
	$MsDataToolsVersion = Get-MsDataToolsVersion
	$SqlServerDataToolsVersion = (Get-SqlServerDataToolsVersion).ProductVersion
	$DotNetFrameworkVersion = Get-DotNetVersion

	Write-Verbose "`nNuget version: $NugetVersion`nMsBuild version: $MsBuildVersion`nSSDT version: $SqlServerDataToolsVersion`nMSDataTools Version: $MsDataToolsVersion`nDotNetVersio: $DotNetFrameworkVersion"

	$sqlConnectionString = "Data Source=$SSISInstanceName;Initial Catalog=master;Integrated Security=SSPI"
	$sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString
	$ssisServer = New-Object Microsoft.SqlServer.Management.IntegrationServices.IntegrationServices $sqlConnection
	
	#Check if catalog is already present, if not create one
	if(!$ssisServer.Catalogs[$SSISCatalogName])	{
		(New-Object Microsoft.SqlServer.Management.IntegrationServices.Catalog($SSISInstanceName, $SSISCatalogName,"P@ssword1")).Create()
	}

	$ssisCatalog = $ssisServer.Catalogs[$SSISCatalogName]

	#Check if Folder is already present, if not create one
	if(!$ssisCatalog.Folders.Item($SSISFolderName))
	{
		(New-Object Microsoft.SqlServer.Management.IntegrationServices.CatalogFolder($ssisCatalog,$SSISFolderName,"Powershell")).Create()
	}

	$ssisFolder = $ssisCatalog.Folders.Item($SSISFolderName)

	#Check if project is already deployed or not, if deployed drop it and deploy again
<#	if($ssisFolder.Projects.Item($ssisProjectName))
	{
	$ssisFolder.Projects.Item($ssisProjectName).Drop()
	}#>
	$IspacResolvedPath = Resolve-Path ($IspacPackagePath)
	
	if(!$ssisFolder.Projects.Item($SSISProjectName))
	{
		$ssisFolder.DeployProject($SSISProjectName,[System.IO.File]::ReadAllBytes($IspacResolvedPath))
	}

	#Access deployed project
	$ssisProject = $ssisFolder.Projects.Item($SSISProjectName)

	$ssisProject.Alter()
}