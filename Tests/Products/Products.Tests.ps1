#handle PS2
if(-not $PSScriptRoot)
{
    $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}
$PSVersion = $PSVersionTable.PSVersion.Major


Describe "Get-WooCommerceProduct"  {
    
    Context "Testfile" { 

        Set-StrictMode -Version latest

        It "Should list all files in systemdrive" {
            (Get-ChildItem -Path $env:systemdrive).Count | Should -BeGreatherThan 0
        }
    }
}

