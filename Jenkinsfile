def PowerShell(psCmd) {
    bat "powershell.exe -NonInteractive -ExecutionPolicy Bypass -File '$psCmd'"
}

node {
	stage('Source') {
		checkout scm
		echo "Running ${env.WORKSPACE} on ${env.JENKINS_URL}"
	}
	stage('Build') {
		PowerShell("'${env.WORKSPACE}\\..\\Tests\\appveyor.pester.ps1'")
	}
}