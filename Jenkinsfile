node {
	stage('Checkout') {
		checkout scm
		echo "Running ${env.WORKSPACE} on ${env.JENKINS_URL}"
	}
	stage('Build') {
		// powershell(returnStatus: true, script: 'env.WORKSPACE\Tests')
	}
}