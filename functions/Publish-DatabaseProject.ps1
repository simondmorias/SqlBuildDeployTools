Function Publish-DatabaseProject
{
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
        [ValidateSet("2008-R2","2012","2014","2016")]
        [string]$SqlServerVersion,

        [parameter(Position=8)]
        [string]$Configuration='Debug',
        [switch]$DacpacRegister,        
        [string]$DacpacApplicationName = $DatabaseName,
        [string]$DacpacApplicationVersion = "1.0.0.0"
    )
    $StartTime = Get-Date
	$SqlServerDataToolsVersion = (Get-SqlServerDataToolsVersion).ProductVersion
    Write-Verbose "SSDT version: $SqlServerDataToolsVersion"
    
    $DacAssembly = 'Microsoft.SqlServer.Dac.dll'
    $DacAssemblyPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\130"
    
    Write-Verbose "Loading DacFx assembly from $DacAssemblyPath\$DacAssembly"
    Add-Type -Path (Join-Path $DacAssemblyPath $DacAssembly)

    # if the directory was specified, find the name of the sql project file
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
    
    [xml]$ProjectFileContent = Get-Content $DatabaseProjectFile
    $DACPACLocation = "$DatabaseProjectPath\bin\$Configuration\" + $ProjectFileContent.Project.PropertyGroup.Name[0] + ".dacpac"
    $DACPACLocation = (Get-ChildItem $DACPACLocation).FullName # get the absolute path
    Write-Verbose "Dacpac location: $DACPACLocation"

    if(Test-Path ($DACPACLocation)) {
        $dacpac = [Microsoft.SqlServer.Dac.DacPackage]::Load($DACPACLocation)
    }
    else {
        throw "Could not load dacpac from $DACPACLocation"
    }    

    if(-not ($PSBoundParameters.ContainsKey('PublishProfile'))) {
        $PublishProfilesFound = (Get-ChildItem $DatabaseProjectPath\*.publish.xml).Count
        if($PublishProfilesFound -eq 1) {            
            $PublishProfile = Join-Path $DatabaseProjectPath (Get-ChildItem $DatabaseProjectPath\*.publish.xml).Name
            Write-Verbose "Using Publish Profile: $PublishProfile"
        } else {
            Write-Warning "-PublishProfile parameter was not specified. Could not find alternative Publish Profile, $PublishProfilesFound publish profiles found."
        }
    }
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
    if([string]::IsNullOrEmpty($InstanceName) -or [string]::IsNullOrEmpty($DatabaseName)) {
        throw "DatabaseName or InstanceName was not supplied and could not discover from publish profile $PublishProfile"
    } else {
        Write-Verbose "Discovered InstanceName: $InstanceName, DatabaseName: $DatabaseName"
    }

    Write-Verbose "`nDatabaseProjectPath: $DatabaseProjectPath`nDatabaseProjectFile: $DatabaseProjectFile`nDACPACLocation: $DACPACLocation"
    Write-Verbose "`nInstanceName: $InstanceName`nDatabaseName: $DatabaseName"
    $dacServices = New-Object Microsoft.SqlServer.Dac.DacServices (Get-ConnectionString -InstanceName $InstanceName -DatabaseName $DatabaseName -SqlLogin $SqlLogin -Password $Password)

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