function Get-ScriptDirectory
{
<#
	.SYNOPSIS
		Get-ScriptDirectory returns the proper location of the script.

	.OUTPUTS
		System.String
	
	.NOTES
		Returns the correct path within a packaged executable.
#>
	[OutputType([string])]
	param ()
	if ($null -ne $hostinvocation)
	{
		Split-Path $hostinvocation.MyCommand.path
	}
	else
	{
		Split-Path $script:MyInvocation.MyCommand.Path
	}
}

#Sample variable that provides the location of the script

#handle PS2
if(-not $PSScriptRoot)
{
    [string]$PSScriptRoot = Get-ScriptDirectory
    #$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}

$PSVersion = $PSVersionTable.PSVersion.Major
$script:consumerKey = "ck_4152c4f7449ceff479498be90607bb905761d9b1"
$script:cosumerSecret = "cs_e8e8bf615e8cc3fcf56415ace8d8c04a04551ab6"
$script:url = "https://cloudra.de"

Import-Module -Force $PSScriptRoot\..\..\Woocommerce



Describe "Set-WooCommerceCredential"  {
    
    Context "Success" { 

        Set-StrictMode -Version latest

        It "Check the credentials and return a msg" {
            Set-WooCommerceCredential -url $script:url -apiKey $script:consumerKey -apiSecret $script:cosumerSecret | Should -Be "Credentials set correctly"
        }
    }

    Context "Success without msg" {
        Set-StrictMode -Version latest

        It "Check the credentials without a msg" {
            Set-WooCommerceCredential -url $script:url -apiKey $script:consumerKey -apiSecret $script:cosumerSecret -noMsg | Should -BeNullOrEmpty
        }
    }

    Context "Error" {
        Set-StrictMode -Version latest

        It "Throw an error" {
            
            {Set-WooCommerceCredential -url $script:url -apiKey "testkey" -apiSecret $script:cosumerSecret} | Should -Throw

        }
    }
}