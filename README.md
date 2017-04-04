# SQL Server Build and Deploy Tools
This module makes building and deploying SQL Server database and SSIS projects easier.

# Usage
## Initialize-DatabaseProject
Builds a Sql Server Data Tools project to produce a .dacpac file.

Parameters:
 * **-DatabaseProjectPath**: The path to the project file. This can be the folder or the .sqlproj file path.
 * **[-TargetVersion]**: Target version to build. Default is 14.
 * **[-SqlServerDataToolsPath]**: If Sql Server Data Tools has been installed in a different location to the default, specify it here.
 * **[-MSBuildPath]**: The path to MSBuild. If this is different to the default specify it here.
 * **[-BuildConfiguration]**: The configuration setting to build. Default is Debug.
 * **[-Verbose]**: Shows details of the build, if omitted minimal information is output.

### Example

`Initialize-DatabaseProject -DatabaseProjectPath C:\Projects\MyDatabaseProject`

## Initialize-SSISProject
Builds a Sql Server Integration Services project to produce a .ispac file.

Parameters:
 * **-SSISProjectPath**: The path to the SSIS project file. This can be the folder or the .dtproj file path.
 * **[-SolutionPath]**: The path to the solution that this SSIS project belongs to.
 * **[-SqlServerDataToolsPath]**: If Sql Server Data Tools has been installed in a different location to the default, specify it here.
 * **[-BuildConfiguration]**: The configuration setting to build. Default is Development.
 * **]-Verbose]**: Shows details of the build, if omitted minimal information is output.

### Example

`Initialize-SSISProject -SSISProjectPath C:\Projects\MySSISProject`

## Publish-DatabaseProject
Deploys or generates a script to deploy a SQL Server database project to a SQL Server instance.

Parameters:
 * **-DatabaseProjectPath**: The path to the project file. This can be the folder or the .sqlproj file path.
 * **[-PublishProfile]**: The path to the publish profile. If not specified, the function will look for one in the root.
 * **[-DeployOption]**: Can be one of the following with a default of 'DACPAC_DEPLOY'
    * 'DACPAC_DEPLOY': Deploys the dacpac to a SQL Server database.
    * 'DACPAC_SCRIPT': Generates a deployment script in the dacpac location, but  does not deploy to the target.
    * 'DACPAC_REPORT': Generates an xml deployment report, but does not deploy to the target.
 * **[-InstanceName]**:The Sql Server instance to deploy to. If specified will override what is in the publish profile.
 * **[-DatabaseName]**:The database name to deploy to. If specified will override what is in the publish profile.
 * **[-SqlLogin]**:If using SQL Authentication, this is the SQL Login. Overrides the publish profile.
 * **[-Password]**:If using SQL Authentication, this is the password for the SQL Login. Overrides the publish profile.
 * **[-BuildConfiguration]**: The Build Configuration  to deploy. Default is Debug.
 * **[-DacpacRegister]**: Switch to specify whether to register the dacpac on the server or not. Defaults to off
 * **[-DacpacApplicationName]**: The name of the dacpac when registering with the server. Defaults to the database name
 * **[-DacpacApplicationVersion]**: The version number to be applied to the registered dacpac on the server.
 * **[-Verbose]**: Shows details of the deployment, if omitted minimal information is output.

### Example
`Publish-DatabaseProject -DatabaseProjectPath C:\Projects\MyDatabaseProject -PublishProfile C:\Projects\MyDatabaseProject\dev.publish.xml`

# Requirements
 * Admin rights where it is run from.
 * Nuget command line. This module will attempt to auto-install it if missing.
 * Microsoft.Data.Tools.Msbuild nuget package. This module will attempt to auto-install it if missing.
 * MSBuild. This module will attempt to auto-install it if missing.
 * SQL Server Data Tools in order to build and deploy SSIS Projects. Will not be auto-installed if missing.

# Tested on
 * Windows 10
 * Windows Server 2016
 * Windows Server 2012 R2
 * SQL Server 2016
