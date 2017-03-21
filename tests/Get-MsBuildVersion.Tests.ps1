$here = Split-Path $MyInvocation.MyCommand.Path
$module = 'SqlBuildDeployTools'
Get-Module SqlBuildDeployTools | Remove-Module -Force
Import-Module .\SqlBuildDeployTools.psm1 -Force
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '.Tests\.', '.'

$function = 'Get-MsBuildVersion'

Describe "$function tests" -Tags 'Internal' {
    
    It 'Should return a version 14 if MsBuild installed with no params' {
        $MsBuildVersion = Get-MsBuildVersion
        $MsBuildVersion | should not beNullOrEmpty
        $MsBuildVersion.Split('.')[0] | should be "14"
    }
}