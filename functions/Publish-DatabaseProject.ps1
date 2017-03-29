Function Publish-DatabaseProject
{
    [cmdletbinding()]
    param (
        [parameter(Position=0,            
            Mandatory=$true)]
        [string]$DatabaseProjectPath,
        
        [parameter(Position=1,
            ParameterSetName="PublishProfile")]
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
	$MsDataToolsVersion = (Get-MsDataToolsVersion).Major
    Write-Verbose "MsDataTools version: $MsDataToolsVersion"
    
    Write-Verbose "Loading DacFx assembly"
    Add-Type -Path "$env:SBDT_MSDATATOOLSPATH\Microsoft.SqlServer.Dac.dll"

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

    if(Test-Path ($DACPACLocation)) {
        $dacpac = [Microsoft.SqlServer.Dac.DacPackage]::Load($DACPACLocation)
    }
    else {
        throw "Could not load dacpac from $DACPACLocation"
    }    
    Write-Verbose "`nDatabaseProjectPath: $DatabaseProjectPath`nDatabaseProjectFile: $DatabaseProjectFile`nDACPACLocation: $DACPACLocation"
    $dacServices = New-Object Microsoft.SqlServer.Dac.DacServices (Get-ConnectionString -InstanceName $InstanceName -DatabaseName $DatabaseName -SqlLogin $SqlLogin -Password $Password)

    if(-not ($PSBoundParameters.ContainsKey($PublishProfile))) {
        if((Get-ChildItem $DatabaseProjectPath\*.publish.xml).Count -eq 1) {            
            $PublishProfile = Join-Path $DatabaseProjectPath (Get-ChildItem $DatabaseProjectPath\*.publish.xml).Name
            Write-Verbose "Using Publish Profile: $PublishProfile"
        } else {
            throw "$PublishProfile parameter was not specified and more than one publish profile was found. Please specify the -PublishProfile parameter and try again."
        }
    }
    if (Test-Path $PublishProfile) {
        $dacProfile = [Microsoft.SqlServer.Dac.DacProfile]::Load($PublishProfile)
        [xml]$PublishProfileContent = Get-Content $PublishProfile
    } else {
        throw "$PublishProfile publish profile path is invalid. Name should end with .publish.xml"
    }
    $dacPacDeployOptions = $dacProfile.DeployOptions    

    # if connection string and database name not specified, use the one in the publish profile

    try {
        switch ($DeployOption) {
            'DACPAC_DEPLOY' {
                Write-Output "Deploying database $DatabaseName to SQL Server instance $InstanceName"
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
        $CompletionMessage = "Success. Time elapsed (HH:MM:SS:MS) {0:g}" -f $ElapsedTime
        Write-Output $CompletionMessage

    }
    catch [Microsoft.SqlServer.Dac.DacServicesException] { 
        throw ("Deployment failed: {0} Reason: {1}" -f $_.Exception.Message, $_.Exception.InnerException.Message) 
    }
    catch {
        throw
    }  
}