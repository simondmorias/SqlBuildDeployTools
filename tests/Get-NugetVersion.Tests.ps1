$here = Split-Path $MyInvocation.MyCommand.Path
$module = 'SqlBuildDeployTools'
Get-Module SqlBuildDeployTools | Remove-Module -Force
Import-Module .\SqlBuildDeployTools.psm1 -Force
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '.Tests\.', '.'

$function = 'Get-NugetVersion'

Describe "$function tests" -Tags 'Internal' {
    
    It 'Should return a version number if Nuget installed' {
         $version = Get-NugetVersion
         $version | should not beNullOrEmpty        
         $version | should match "\d\.\d\.\d\.\d+"
    }
}