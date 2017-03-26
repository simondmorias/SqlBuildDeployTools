$SourcePath = "\\TULIP\Software"

$here = Split-Path $MyInvocation.MyCommand.Path
$module = 'SqlBuildDeployTools'
Get-Module SqlBuildDeployTools | Remove-Module -Force
Import-Module .\SqlBuildDeployTools.psm1 -Force
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '.Tests\.', '.'

Describe "MsDataTools tests" -Tags 'Internal' {

    It 'Should install MsDataTools with no parameters' {
        Install-MsDataTools -Verbose
        $Version = Get-MsDataToolsVersion
        $Version | should not beNullOrEmpty
        ($Version).Major | should be "13"
    }



}