#handle PS2
if(-not $PSScriptRoot)
{
    $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}

$PSVersion = $PSVersionTable.PSVersion.Major
$script:consumerKey = "ck_4152c4f7449ceff479498be90607bb905761d9b1"
$script:cosumerSecret = "cs_e8e8bf615e8cc3fcf56415ace8d8c04a04551ab6"
$script:url = "https://cloudra.de"

Import-Module -Force $PSScriptRoot\..\Woocommerce

Set-WooCommerceCredential -url $script:url -apiKey $script:consumerKey -apiSecret $script:cosumerSecret

Describe "Get-WooCommerceProduct"  {
    
    Context "Strict mode" { 

        Set-StrictMode -Version latest

        It "Should list all Products in WooCommerce" {
            Get-WooCommerceProduct -all | Should not -BeNullOrEmpty  
        }
    }
}

<#
Describe "Get-DiskPartDisk" {
    
    Context "Strict mode" { 

        Set-StrictMode -Version latest

        It "Should list disks on a local system PS$PSVersion" {

            $OutArray = @( Get-DiskPartDisk -ComputerName $env:COMPUTERNAME )
            
            #Hopefully you have at least one disk.
            $OutArray.Count | Should BeGreaterThan 0
        }
    }
}

Describe "Get-DiskPartVolume"  {
    
    Context "Strict mode" { 

        Set-StrictMode -Version latest

        It "Should list volumes on a local system PS$PSVersion" {

            $OutArray = @( Get-DiskPartVolume -ComputerName $env:COMPUTERNAME )
            
            #Hopefully you have at least one volume.
            $OutArray.Count | Should BeGreaterThan 0

            #Does it have a subset of props?
                $ActualProperties = $OutArray[0].PSObject.Properties | Select -ExpandProperty Name
                $ExpectedProperties = echo ComputerName VolumeNumber Letter Label
                $Comparison = Compare-Object -ReferenceObject $ActualProperties -DifferenceObject $ExpectedProperties
            
                ( $Comparison | Select -ExpandProperty SideIndicator ) -Contains "=>" | Should be $False
        }
    }
}
#>