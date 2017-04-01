#!groovy
node  {
	stage ('checkout') {

		// delete the workspace from the last build
		deleteDir()

		// checkout the project from git as configured in the project configuration
		checkout scm
	}
	// initialize
	echo "Build Number: ${env.BUILD_NUMBER}"
	echo "Build url: ${env.BUILD_URL}"
	echo "Workspace: ${env.WORKSPACE}"
	echo "NUGET_REPO: ${NUGET_REPO}"	
	echo "JOB BASE NAME: ${JOB_BASE_NAME}"

	stage ('package') {
		bat "nuget pack ${JOB_BASE_NAME}.nuspec -properties id=${JOB_BASE_NAME};description=${BUILD_URL} -version ${BUILD_NUMBER}"
	}
	
	stage ('publish') {
		// publish  the Nuget package to the Nuget Repository
		bat "nuget push ${JOB_BASE_NAME}.${BUILD_NUMBER}.nupkg ${API_KEY} -Source ${NUGET_REPO}"
	}
}