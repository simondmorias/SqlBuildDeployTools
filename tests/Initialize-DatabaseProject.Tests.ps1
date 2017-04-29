$SourcePath = "\\TULIP\Software"

$here = Split-Path $MyInvocation.MyCommand.Path
$module = 'SqlBuildDeployTools'
Get-Module SqlBuildDeployTools | Remove-Module -Force
Import-Module .\SqlBuildDeployTools.psm1 -Force
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '.Tests\.', '.'
$here
Describe "Initialize-DatabaseProject tests" -Tags 'Public' {

    It 'Build test project with minimum params' {
        # build a test project and store the output
        $succeeded = $false
        $Output = Initialize-DatabaseProject -DatabaseProjectPath "$here\SqlBuildDeployToolsPesterTest\database.pestertest\"
        foreach ($line in $output) {
            if($line -match "Build Succeeded") { $succeeded = $true }
        }
        # now test the output
        $succeeded | Should Be True
    }



}