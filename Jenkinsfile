def PowerShell(psCmd) {
    psCmd=psCmd.replaceAll("%", "%%")
    bat "powershell.exe -NonInteractive -ExecutionPolicy Bypass -Command \"\$ErrorActionPreference='Stop';[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;$psCmd;EXIT \$global:LastExitCode\""
}

node {
	stage('Source') {
		checkout scm
		echo "Running ${env.WORKSPACE} on ${env.JENKINS_URL}"
	}
	stage('Build') {
		PowerShell(". '..\\Tests\\appveyor.pester.ps1'")
	}
}