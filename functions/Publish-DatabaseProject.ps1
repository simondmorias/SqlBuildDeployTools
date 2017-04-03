Function Publish-DatabaseProject
{
<#
.SYNOPSIS 
Publish-DatabaseProject deploys a Sql Server project to a Sql Server instance, or generates a deployment script.

.DESCRIPTION
This function uses SSDT to deploy a database project to a single SQL Server instance. The InstanceName and DatabaseName can be supplied using parameters or a publish profile can be supplied. If neither are supplied, the function tries to find a publish profile in the project root directory.

.PARAMETER DatabaseProjectPath
The path to the project file. This can be the folder or the .sqlproj file path.

.PARAMETER PublishProfile
The path to the publish profile. If not specified, the function will look for one in the root.

.PARAMETER DeployOption
Can be one of the following with a default of 'DACPAC_DEPLOY'
    'DACPAC_DEPLOY': Deploys the dacpac to a SQL Server database.
    'DACPAC_SCRIPT': Generates a deployment script in the dacpac location, but does not deploy to the target.
    'DACPAC_REPORT': Generates an xml deployment report, but does not deploy to the target.

.PARAMETER InstanceName
The Sql Server instance to deploy to. If specified will override what is in the publish profile.

.PARAMETER DatabaseName
The database name to deploy to. If specified will override what is in the publish profile.

.PARAMETER SqlLogin
If using SQL Authentication, this is the SQL Login. Overrides the publish profile.

.PARAMETER Password
If using SQL Authentication, this is the password for the SQL Login. Overrides the publish profile.

.PARAMETER BuildConfiguration
The Build Configuration  to deploy. Default is Debug.

.PARAMETER DacpacRegister
Switch to specify whether to register the dacpac on the server or not. Defaults to off

.PARAMETER DacpacApplicationName
The name of the dacpac when registering with the server. Defaults to the database name

.PARAMETER DacpacApplicationVersion
The version number to be applied to the registered dacpac on the server.

.PARAMETER Verbose
Shows details of the deployment, if omitted minimal information is output.

.NOTES
Author: Mark Allison

Requires: 
	SQL Server Data Tools. This module will not auto-install it.
	Nuget (if nuget is not detected, this function will try to install it)
    Admin rights.
    Account running the script must have CREATE DATABASE and db_owner privileges in the target database.

.EXAMPLE   
Publish-DatabaseProject -DatabaseProjectPath C:\Projects\MyDatabaseProject -PublishProfile C:\Projects\MyDatabaseProject\dev.publish.xml

Deploys the project in C:\Projects\MyDatabaseProject to the server details in publish profile C:\Projects\MyDatabaseProject\dev.publish.xml
#>    
    [cmdletbinding()]
    param (
        [parameter(Position=0,            
            Mandatory=$true)]
        [string]$DatabaseProjectPath,
        
        [parameter(Position=1)]
        [string]$PublishProfile,

        [parameter(Position=2)]
        [ValidateSet('DACPAC_DEPLOY','DACPAC_SCRIPT','DACPAC_REPORT')]
        [string]$DeployOption="DACPAC_DEPLOY",
        
        [parameter(Position=3,
            ParameterSetName="ConnectionString")]
        [string]$InstanceName,

        [parameter(Position=4,
            ParameterSetName="ConnectionString")]        
        [string]$DatabaseName,
        
        [parameter(Position=5,
            ParameterSetName="ConnectionString")]
        [string]$SqlLogin,

        [parameter(Position=6,
            ParameterSetName="ConnectionString")]
        [string]$Password,
        
        [parameter(Position=7)]
        [string]$BuildConfiguration='Debug',
        [switch]$DacpacRegister,        
        [string]$DacpacApplicationName = $DatabaseName,
        [string]$DacpacApplicationVersion = "1.0.0.0"
    )
    $StartTime = Get-Date
    $MsDataToolsVersion = Get-MsDataToolsVersion
	$SqlServerDataToolsVersion = (Get-SqlServerDataToolsVersion).ProductVersion
    Write-Verbose "SSDT version: $SqlServerDataToolsVersion"
    
    # try and load the DAC assembly
    try {
        $DacAssembly = 'Microsoft.SqlServer.Dac.dll'
        if([string]::IsNullOrEmpty($env:SBDT_MSDATATOOLSPATH)) {
            Write-Warning "Ms Data Tools could not be found. Trying to use SSDT path instead."
            $DacAssemblyPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\130"
        } else {
            $DacAssemblyPath = $env:SBDT_MSDATATOOLSPATH
        }
        Write-Verbose "Loading DacFx assembly from $DacAssemblyPath\$DacAssembly"
        Add-Type -Path (Join-Path $DacAssemblyPath $DacAssembly)
    }
    catch {
        Write-Warning "Could not load Dac Assembly from $DacAssemblyPath"
        throw
    }

    # if no full path specified for the database project file, find the name of the sql project file
    if($DatabaseProjectPath.EndsWith('.sqlproj')) {
        $DatabaseProjectFile = $DatabaseProjectPath 
        $DatabaseProjectPath = Split-Path $DatabaseProjectPath         
    }
    elseif (Test-Path $DatabaseProjectPath -pathType container) {
        if((Get-ChildItem $DatabaseProjectPath\*.sqlproj).Count -eq 1) {
            $DatabaseProjectFile = Join-Path $DatabaseProjectPath (Get-ChildItem $DatabaseProjectPath *.sqlproj).Name
            $DatabaseProjectPath = $DatabaseProjectPath.TrimEnd('\')
        }
        else {
            throw "Can't find project file"
        }
    }
    Write-Verbose "Database Project Path: $DatabaseProjectPath"
    Write-Verbose "Database Project File: $DatabaseProjectFile"

    # load the dacpac
    [xml]$ProjectFileContent = Get-Content $DatabaseProjectFile
    $DACPACLocation = "$DatabaseProjectPath\bin\$BuildConfiguration\" + $ProjectFileContent.Project.PropertyGroup.Name[0] + ".dacpac"
    $DACPACLocation = (Get-ChildItem $DACPACLocation).FullName # get the absolute path
    Write-Verbose "Dacpac location: $DACPACLocation"

    if(Test-Path ($DACPACLocation)) {
        $dacpac = [Microsoft.SqlServer.Dac.DacPackage]::Load($DACPACLocation)
    }
    else {
        throw "Could not load dacpac from $DACPACLocation"
    }    

    # Publish profile not specified let's try and find one
    if(-not ($PSBoundParameters.ContainsKey('PublishProfile'))) {
        [int]$PublishProfilesFound = (Get-ChildItem $DatabaseProjectPath\*.publish.xml).Count
        if($PublishProfilesFound -eq 1) {            
            $PublishProfile = Join-Path $DatabaseProjectPath (Get-ChildItem $DatabaseProjectPath\*.publish.xml).Name
            Write-Verbose "Using Publish Profile: $PublishProfile"
        } else {
            Write-Warning "-PublishProfile parameter was not specified. Could not find alternative Publish Profile, $PublishProfilesFound publish profiles found."
        }
    }

    # if we have a pulblish profile and the path exists, load it. If not, specify some defaults
    if (-not([string]::IsNullOrEmpty($PublishProfile)) -and (Test-Path $PublishProfile)) {
        Write-Verbose "Loading publish profile from $PublishProfile"
        $dacProfile = [Microsoft.SqlServer.Dac.DacProfile]::Load($PublishProfile)        
    } else {
        Write-Warning "$PublishProfile publish profile not found. Using default deployment options"
        if([string]::IsNullOrEmpty($dacProfile)) {
            $dacProfile = New-Object Microsoft.SqlServer.Dac.DacDeployOptions -Property @{
                'BlockOnPossibleDataLoss' = $true;
                'DropObjectsNotInSource' = $false;
                'ScriptDatabaseOptions' = $true;
                'IgnorePermissions' = $true;
                'IgnoreRoleMembership' = $true
            }
        }        
    }
    # read the publish profile if exists
    if(-not ([string]::IsNullOrEmpty($PublishProfile))) {
        [xml]$PublishProfileContent = Get-Content $PublishProfile        
    } else {        
        if(-not ($PSBoundParameters.ContainsKey('InstanceName')) -or (-not ($PSBoundParameters.ContainsKey('DatabaseName')))) {
            throw "Publish profile could not be loaded AND DatabaseName/InstanceName not specified/found."
        }        
    }
        
    # if instance name or database name not specified, use the one in the publish profile
    if(-not($PSBoundParameters.ContainsKey('DatabaseName')) -and (-not [string]::IsNullOrEmpty($PublishProfileContent))) {
        Write-Verbose "DatabaseName not specified. Attempting to discover from $PublishProfile"
        $DatabaseName = $PublishProfileContent.Project.PropertyGroup.TargetDatabaseName
        Write-Verbose "DatabaseName: $DatabaseName"
    }
    if(-not($PSBoundParameters.ContainsKey('InstanceName')) -and (-not [string]::IsNullOrEmpty($PublishProfileContent))) {
        Write-Verbose "InstanceName not specified. Attempting to discover from $PublishProfile"
        $InstanceName = ($PublishProfileContent.Project.PropertyGroup.TargetConnectionString.Split(';')[0]).Split('=')[1]
        Write-Verbose "InstanceName: $InstanceName"
    }

    # if we can't discover the instance name or database name we need to throw
    if([string]::IsNullOrEmpty($InstanceName) -or [string]::IsNullOrEmpty($DatabaseName)) {
        throw "DatabaseName or InstanceName was not supplied and could not discover from publish profile $PublishProfile"
    } else {
        Write-Verbose "Discovered InstanceName: $InstanceName, DatabaseName: $DatabaseName"
    }

    Write-Verbose "`nDatabaseProjectPath: $DatabaseProjectPath`nDatabaseProjectFile: $DatabaseProjectFile`nDACPACLocation: $DACPACLocation"
    Write-Verbose "`nInstanceName: $InstanceName`nDatabaseName: $DatabaseName"
    $dacServices = New-Object Microsoft.SqlServer.Dac.DacServices (Get-ConnectionString -InstanceName $InstanceName -DatabaseName $DatabaseName -SqlLogin $SqlLogin -Password $Password)

    # we got this far so let's deploy, script or report
    try {
        switch ($DeployOption) {
            'DACPAC_DEPLOY' {
                Write-Output "Deploying database $DatabaseName to SQL Server instance $InstanceName..."
                $dacServices.Deploy($dacpac, $DatabaseName, $true, $dacProfile.DeployOptions, $null)        

                if($DacpacRegister) {
                    Write-Output "Registering dacpac on $InstanceName"
                    $dacServices.Register($DatabaseName, $DacpacApplicationName, $DacpacApplicationVersion)
                }
            }
            'DACPAC_SCRIPT' {
                $GeneratedScript = Join-Path (Split-Path $DACPACLocation) ($InstanceName.Replace('\','_') + "_$DatabaseName`_Deploy.sql")
                Write-Output "Scripting deployment to $GeneratedScript"
                $dacServices.GenerateDeployScript($dacpac, $DatabaseName, $dacProfile.DeployOptions, $null) > $GeneratedScript                   
            }
            'DACPAC_REPORT' {
                $Report = Join-Path (Split-Path $DACPACLocation) ($InstanceName.Replace('\','_') + "_$DatabaseName`_DeployReport.xml")
                Write-Output "Creating report at $Report" 
                $dacServices.GenerateDeployReport($dacpac, $DatabaseName, $dacProfile.DeployOptions, $null) > $Report
            }
        }
        $ElapsedTime = (New-TimeSpan –Start $StartTime –End (Get-Date))
        $CompletionMessage = "Success. Time elapsed: {0:g}" -f $ElapsedTime
        Write-Output $CompletionMessage

    }
    catch [Microsoft.SqlServer.Dac.DacServicesException] { 
        throw ("Deployment failed: {0} Reason: {1}" -f $_.Exception.Message, $_.Exception.InnerException.Message) 
    }
    catch {
        throw
    }  
}