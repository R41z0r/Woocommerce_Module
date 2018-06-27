Import-Module PSScriptAnalyzer
$Results = Invoke-ScriptAnalyzer -Path "$PSScriptRoot\..\Woocommerce" -Recurse -Severity Warning,Error -ErrorAction SilentlyContinue
If ($Results) {
$ResultString = $Results | Out-String
Write-Warning $ResultString
Write-Output "PSScriptAnalyzer output contained one or more result(s) with 'Error' severity Check the 'Tests' tab of this build for more details."
Exit 1

# Failing the build
Throw "Build failed"
}
Else {
Exit 0
}