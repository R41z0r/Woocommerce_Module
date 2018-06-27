node {
	stage('Checkout') {
		checkout scm
	}
	stage('Build') {
		powershell(returnStatus: true, script: 'env.WORKSPACE\Tests')
	}
}