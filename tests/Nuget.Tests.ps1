$SourcePath = "\\TULIP\Software\Nuget"

$here = Split-Path $MyInvocation.MyCommand.Path
$module = 'SqlBuildDeployTools'
Get-Module SqlBuildDeployTools | Remove-Module -Force
Import-Module .\SqlBuildDeployTools.psm1 -Force
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '.Tests\.', '.'

Describe "Nuget tests" -Tags 'Internal' {

    It 'Should install Nuget from internet by default with no parameters' {
        Install-NugetCommandLine
         $version = Get-NugetVersion
         $version | should not beNullOrEmpty        
         $version | should match "\d\.\d\.\d\.\d+"
    }

    It 'Should install Nuget from internet idempotent with -Force' {
        Install-NugetCommandLine -Force
         $version = Get-NugetVersion
         $version | should not beNullOrEmpty        
         $version | should match "\d\.\d\.\d\.\d+"
    }    

    It "Should install Nuget from file share $SourcePath idempotent with -Force" {
        Install-NugetCommandLine -Force -SourcePath $SourcePath
         $version = Get-NugetVersion
         $version | should not beNullOrEmpty        
         $version | should match "\d\.\d\.\d\.\d+"
    }     

    It 'Should return a version number if Nuget installed' {
         $version = Get-NugetVersion
         $version | should not beNullOrEmpty        
         $version | should match "\d\.\d\.\d\.\d+"
    }
}