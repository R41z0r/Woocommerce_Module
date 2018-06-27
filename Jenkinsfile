node {
	stage('Checkout') {
		checkout scm
	}
	stage('Build') {
		powershell -f WORKSPACE\Tests
	}
}