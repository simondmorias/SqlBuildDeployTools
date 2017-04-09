$SourcePath = "\\TULIP\Software"

$here = Split-Path $MyInvocation.MyCommand.Path
$module = 'SqlBuildDeployTools'
Get-Module SqlBuildDeployTools | Remove-Module -Force
Import-Module .\SqlBuildDeployTools.psm1 -Force
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '.Tests\.', '.'

Describe "MsBuild tests" -Tags 'Internal' {

    It 'Should install MsBuild with no parameters' {
        Install-MsBuild
        $MsBuildVersion = Get-MsBuildVersion
        $MsBuildVersion | should not beNullOrEmpty
        $MsBuildVersion.Split('.')[0] | should be "14"
    }

    It 'Should reinstall MsBuild idempotent using with force' {
        Install-MsBuild -Force
        $MsBuildVersion = Get-MsBuildVersion
        $MsBuildVersion | should not beNullOrEmpty
        $MsBuildVersion.Split('.')[0] | should be "14"
    }

    It 'Should reinstall MsBuild idempotent from file share using with force' {
        Install-MsBuild  -Force -SourcePath $SourcePath
        $MsBuildVersion = Get-MsBuildVersion
        $MsBuildVersion | should not beNullOrEmpty
        $MsBuildVersion.Split('.')[0] | should be "14"
    }

    It 'Should not fail idempotent if exists and not force' {
    Install-MsBuild  -SourcePath $SourcePath
    $MsBuildVersion = Get-MsBuildVersion
    $MsBuildVersion | should not beNullOrEmpty
    $MsBuildVersion.Split('.')[0] | should be "14"
    }

}