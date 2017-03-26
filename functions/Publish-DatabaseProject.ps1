Function Publish-DatabaseProject
{
    [cmdletbinding()]
    param (
        [parameter(Mandatory=$true)]
        [string]$DatabaseProjectPath,

        [string]$PublishProfile,
        
        [parameter(ParameterSetName="Connection")]
        [string]$InstanceName,

        [parameter(ParameterSetName="Connection")]
        [string]$DatabaseName,

        [parameter(ParameterSetName="Connection")]
        [string]$SqlLogin,

        [parameter(ParameterSetName="Connection")]
        [string]$Password,

        [parameter(ParameterSetName="Connection")][ValidateSet(
            "2008-R2","2012","2014","2016"
        )]
        [string]$SqlServerVersion,

        [string]$Configuration="Debug"
    )

	$MsDataToolsVersion = Get-MsDataToolsVersion
    Write-Verbose "`nNuget version: $NugetVersion`nMsBuild version: $MsBuildVersion`nMsDataTools version: $MsDataToolsVersion"
    
    Write-Verbose "Adding DacFx type"
    Add-Type -Path "$env:SBDT_MSDATATOOLSPATH\Microsoft.SqlServer.Dac.dll"

    # if the directory was specified, find the name of the project file
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

    if($PSBoundParameters.ContainsKey($PublishProfile)) {
        if((Get-ChildItem $DatabaseProjectPath\*.publish.xml).Count -eq 1) {
            $PublishProfile = (Get-ChildItem $DatabaseProjectPath *.publish.xml).Name
        }
    }
    return $PublishProfile
    
    $dacProfile = [Microsoft.SqlServer.Dac.DacProfile]::Load($PublishProfile)

    

}




function DeployDac([string] $databaseName, [string]$connectionString, [string]$sqlserverVersion, [string]$dacpacPath, [string]$dacpacApplicationName, [string]$dacpacApplicationVersion)
{
    $defaultDacPacApplicationVersion = "1.0.0.0"

    if($PSBoundParameters.ContainsKey('dacpacApplicationVersion'))
    {
        $defaultDacPacApplicationVersion = $defaultDacPacApplicationVersion
    }

    Load-DacFx -sqlserverVersion $sqlserverVersion

    $dacServicesObject = new-object Microsoft.SqlServer.Dac.DacServices ($connectionString)

    $dacpacInstance = [Microsoft.SqlServer.Dac.DacPackage]::Load($dacpacPath)

    try
    {
        $dacServicesObject.Deploy($dacpacInstance, $databaseName,$true) 

        $dacServicesObject.Register($databaseName, $dacpacApplicationName,$defaultDacPacApplicationVersion)

        Write-Verbose("Dac Deployed")
    }
    catch
    {
        $errorMessage = $_.Exception.Message
        Write-Verbose('Dac Deploy Failed: ''{0}''' -f $errorMessage)
    }
}



function Load-DacFx([string]$sqlserverVersion)
{
    $majorVersion = Get-SqlServerMajoreVersion -sqlServerVersion $sqlserverVersion

    $DacFxLocation = "${env:ProgramFiles(x86)}\Microsoft SQL Server\$majorVersion\DAC\bin\Microsoft.SqlServer.Dac.dll"

    try
    {  
        [System.Reflection.Assembly]::LoadFrom($DacFxLocation) | Out-Null
    }
    catch
    {
        Throw "$LocalizedData.DacFxInstallationError"
    }
}