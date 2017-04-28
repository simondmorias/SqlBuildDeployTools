#!groovy
node  {
	stage ('checkout') {
		deleteDir()
		checkout scm
	}
	// initialize
	echo "Build Number: ${env.BUILD_NUMBER}"
	echo "Build url: ${env.BUILD_URL}"
	echo "Workspace: ${env.WORKSPACE}"
	echo "NUGET_REPO: ${NUGET_REPO}"	
	echo "JOB BASE NAME: ${JOB_BASE_NAME}"

	stage ('test') {
		timeout (5) {
			bat 'powershell -Command $results = Invoke-Pester -PassThru; foreach ($result in $results) {if($_.Passed -eq $false) {$result}};if($results.FailedCount -gt 0) {exit 1}'
		}
	}

	stage ('package') {
		timeout (1) {
			bat "nuget pack ${JOB_BASE_NAME}.nuspec -properties id=${JOB_BASE_NAME};description=${BUILD_URL} -version ${BUILD_NUMBER} -NoPackageAnalysis"
		}
	}
	
	stage ('publish') {
		timeout (1) {
			bat "nuget push ${JOB_BASE_NAME}.${BUILD_NUMBER}*.nupkg -Source ${NUGET_REPO}"
		}
	}
}