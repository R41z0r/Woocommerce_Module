node {
	stage('Source') {
		checkout scm
		echo "Running ${env.WORKSPACE} on ${env.JENKINS_URL}"
	}
	stage('Pester') {
		powershell "& \"${env.WORKSPACE}\\Tests\\appveyor.pester.ps1\""
	}
	stage("PublishTestReport"){
		nunit testResultsPattern: "${env.WORKSPACE}\\PesterResults5.xml"
	}
}